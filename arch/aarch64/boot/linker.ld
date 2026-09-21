ENTRY(_start)
OUTPUT_ARCH(aarch64)

FEROS_LOAD_ADDRESS = 0x03FE0000;
FEROS_IMAGE_CAPACITY = 472 * 512;

MEMORY
{
    STAGE0 (rwx) : ORIGIN = FEROS_LOAD_ADDRESS, LENGTH = FEROS_IMAGE_CAPACITY
}

SECTIONS
{
    . = ORIGIN(STAGE0);
    __image_start = .;

    .text : ALIGN(16)
    {
        KEEP(*(.text.boot))
        *(.text*)
    } > STAGE0

    .rodata : ALIGN(16)
    {
        *(.rodata*)
    } > STAGE0

    .data : ALIGN(16)
    {
        *(.data*)
    } > STAGE0

    .bss (NOLOAD) : ALIGN(16)
    {
        __bss_start = .;
        *(.bss*)
        *(COMMON)
        __bss_end = .;
    } > STAGE0

    __image_end = .;

    /DISCARD/ :
    {
        *(.comment)
        *(.note*)
        *(.eh_frame*)
    }

    ASSERT(
        __image_end - __image_start <= LENGTH(STAGE0),
        "FeROS Stage 0 exceeds the RKNS payload capacity"
    )
}
