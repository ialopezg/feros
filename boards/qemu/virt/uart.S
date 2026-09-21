/*
 * FeROS - Ferrite Retro Operating System
 *
 * QEMU virt early UART support.
 *
 * QEMU provides the PL011 UART in a usable state for the Stage 0 console.
 * No additional hardware initialization is currently required.
 */

.section .text
.align 4

.equ UART0_BASE,   0x09000000
.equ UART_DR,      0x00
.equ UART_FR,      0x18
.equ UART_FR_TXFF, (1 << 5)

/*
 * void platform_uart_init(void)
 *
 * Satisfies the FeROS early-console platform contract.
 *
 * The QEMU virt platform exposes UART0 ready for early output, so no
 * initialization is required here.
 */
.global platform_uart_init
.type platform_uart_init, %function

platform_uart_init:
    ret

.size platform_uart_init, . - platform_uart_init

/*
 * void platform_uart_putc(uint8_t character)
 *
 * x0 = character
 *
 * Waits until the PL011 transmit FIFO can accept a character and writes it
 * directly to the data register.
 */
.global platform_uart_putc
.type platform_uart_putc, %function

platform_uart_putc:
    ldr     x1, =UART0_BASE

1:
    ldr     w2, [x1, #UART_FR]
    tst     w2, #UART_FR_TXFF
    b.ne    1b

    str     w0, [x1, #UART_DR]
    ret

.size platform_uart_putc, . - platform_uart_putc