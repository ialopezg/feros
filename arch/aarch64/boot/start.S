/*
 * FeROS AArch64 entry point.
 *
 * This is the first FeROS code executed by the RK3566 bring-up path.
 * No runtime environment is assumed.
 */

.section .text.boot
.align 4

.global _start
.type   _start, %function

.extern rk3566_uart_putc

_start:
    /*
     * The first physical bring-up experiment relies on UART2 already being
     * configured by the preceding RK3566 bootstrap stage.
     *
     * Do not assume a stack, C runtime, MMU, exceptions, or initialized DRAM.
     */

    mov     w0, #'F'
        bl      rk3566_uart_putc

    mov     w0, #'e'
        bl      rk3566_uart_putc

    mov     w0, #'R'
        bl      rk3566_uart_putc

    mov     w0, #'O'
        bl      rk3566_uart_putc

    mov     w0, #'S'
        bl      rk3566_uart_putc

    mov     w0, #'\r'
        bl      rk3566_uart_putc

    mov     w0, #'\n'
        bl      rk3566_uart_putc

1:
    wfe
    b       1b

.size _start, . - _start
