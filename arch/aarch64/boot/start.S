/*
 * FeROS AArch64 entry point.
 *
 * This is the first FeROS code executed by the platform bring-up path.
 * No runtime environment is assumed.
 */

.section .text.boot
.align 4

.global _start
.type _start, %function

.extern platform_uart_putc

_start:
    mov     w0, #'F'
    bl      platform_uart_putc

    mov     w0, #'e'
    bl      platform_uart_putc

    mov     w0, #'R'
    bl      platform_uart_putc

    mov     w0, #'O'
    bl      platform_uart_putc

    mov     w0, #'S'
    bl      platform_uart_putc

    mov     w0, #'\r'
    bl      platform_uart_putc

    mov     w0, #'\n'
    bl      platform_uart_putc

1:
    wfe
    b       1b

.size _start, . - _start