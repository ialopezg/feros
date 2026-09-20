/*
 * FeROS - Ferrite Retro Operating System
 *
 * RK3566 early UART support.
 *
 * This implementation provides the minimum functionality required to emit
 * characters before a C runtime environment exists.
 */

.section .text
.align 4

/*
 * RK3566 UART2
 *
 * Base address: 0xFE660000
 * Register shift: 2
 *
 * The UART is compatible with the Synopsys DesignWare APB UART / 16550
 * register model.
 */
.equ UART2_BASE, 0xFE660000

/* UART register offsets after applying reg-shift = 2. */
.equ UART_THR, 0x00
.equ UART_LSR, 0x14

/* Line Status Register bits. */
.equ UART_LSR_THRE, (1 << 5)

/*
 * void rk3566_uart_putc(uint8_t character)
 *
 * x0 = character
 *
 * The routine assumes UART2 has already been initialized by the preceding
 * boot environment. This is intentional for the first FeROS bring-up.
 */
.global platform_uart_putc
.type platform_uart_putc, %function

platform_uart_putc:
    ldr     x1, =UART2_BASE

1:
    ldr     w2, [x1, #UART_LSR]
    tst     w2, #UART_LSR_THRE
    b.eq    1b

    str     w0, [x1, #UART_THR]

    ret

.size platform_uart_putc, . - platform_uart_putc