/*
 * FeROS - Ferrite Retro Operating System
 *
 * QEMU virt early UART support.
 */

.section .text
.align 4

.equ UART0_BASE,   0x09000000
.equ UART_DR,      0x00
.equ UART_FR,      0x18
.equ UART_FR_TXFF, (1 << 5)

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