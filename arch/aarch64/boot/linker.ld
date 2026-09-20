ENTRY(_start)

SECTIONS
{
    . = 0x00000000;

    .text : ALIGN(16)
        {
            KEEP(*(.text.boot))
            *(.text*)
        }

    .rodata : ALIGN(16)
        {
            *(.rodata*)
        }

    .data : ALIGN(16)
        {
            *(.data*)
        }

    .bss : ALIGN(16)
            {
                __bss_start = .;
                *(.bss*)
                *(.COMMON)
                __bss_end = .;
            }

    /DISCARD/ :
        {
            *(.comment)
            *(.note*)
            *(.eh_frame*)
        }
}