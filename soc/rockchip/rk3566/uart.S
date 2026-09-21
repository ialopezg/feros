/*
 * FeROS - Ferrite Retro Operating System
 *
 * RK3566 early UART support.
 *
 * This implementation configures the RK3566 UART2 M0 pinmux and initializes
 * the UART for early console output before a C runtime environment exists.
 */

.section .text
.align 4

/*
 * RK3566 UART2 M0 pinmux.
 *
 * UART2 M0:
 *   GPIO0_D0 -> UART2_RX
 *   GPIO0_D1 -> UART2_TX
 */
.equ GRF_IOFUNC_SEL3,          0xFDC6030C
.equ PMUGRF_GPIO0D_IOMUX_L,   0xFDC20018

/*
 * Rockchip registers use a high-word write mask.
 *
 * GRF_IOFUNC_SEL3:
 *   Select UART2 M0.
 *
 * PMUGRF_GPIO0D_IOMUX_L:
 *   Select function 1 for GPIO0_D0 and GPIO0_D1.
 */
.equ UART2_M0_IOFUNC,          0x0C000000
.equ UART2_M0_IOMUX,           0x00770011

/*
 * RK3566 UART2.
 *
 * Base address: 0xFE660000
 * Input clock:  24 MHz
 * Baud rate:    1,500,000
 * Divisor:      1
 * Register shift: 2
 *
 * The UART is compatible with the Synopsys DesignWare APB UART / 16550
 * register model.
 */
.equ UART2_BASE,               0xFE660000

/* UART register offsets after applying reg-shift = 2. */
.equ UART_RBR_THR_DLL,         0x00
.equ UART_IER_DLH,             0x04
.equ UART_FCR,                 0x08
.equ UART_LCR,                 0x0C
.equ UART_MCR,                 0x10
.equ UART_LSR,                 0x14

/* UART configuration values. */
.equ UART_FCR_ENABLE,          0x07
.equ UART_LCR_DLAB_8N1,       0x83
.equ UART_LCR_8N1,            0x03
.equ UART_MCR_DEFAULT,         0x03
.equ UART_DIVISOR,             0x01

/* Line Status Register bits. */
.equ UART_LSR_THRE,            (1 << 5)

/*
 * void platform_uart_init(void)
 *
 * Configures the RK3566 UART2 M0 pinmux and initializes UART2 for
 * 1,500,000 baud, 8 data bits, no parity, and one stop bit.
 *
 * No stack or C runtime is required.
 */
.global platform_uart_init
.type platform_uart_init, %function

platform_uart_init:
    /* Select UART2 M0 in GRF_IOFUNC_SEL3. */
    ldr     x0, =GRF_IOFUNC_SEL3
    ldr     w1, =UART2_M0_IOFUNC
    str     w1, [x0]
    dmb     sy

    /* Route GPIO0_D0/D1 to UART2 RX/TX. */
    ldr     x0, =PMUGRF_GPIO0D_IOMUX_L
    ldr     w1, =UART2_M0_IOMUX
    str     w1, [x0]
    dmb     sy

    ldr     x0, =UART2_BASE

    /* Disable UART interrupts. */
    str     wzr, [x0, #UART_IER_DLH]

    /* Configure modem control. */
    mov     w1, #UART_MCR_DEFAULT
    str     w1, [x0, #UART_MCR]

    /* Enable and reset FIFOs. */
    mov     w1, #UART_FCR_ENABLE
    str     w1, [x0, #UART_FCR]

    /* Enable divisor-latch access and select 8N1. */
    mov     w1, #UART_LCR_DLAB_8N1
    str     w1, [x0, #UART_LCR]

    /* 24 MHz / (16 * 1) = 1,500,000 baud. */
    mov     w1, #UART_DIVISOR
    str     w1, [x0, #UART_RBR_THR_DLL]
    str     wzr, [x0, #UART_IER_DLH]

    /* Disable divisor-latch access and retain 8N1. */
    mov     w1, #UART_LCR_8N1
    str     w1, [x0, #UART_LCR]

    ret

.size platform_uart_init, . - platform_uart_init

/*
 * void platform_uart_putc(uint8_t character)
 *
 * x0 = character
 *
 * Waits until the UART transmitter can accept a character and writes it
 * directly to the transmit holding register.
 */
.global platform_uart_putc
.type platform_uart_putc, %function

platform_uart_putc:
    ldr     x1, =UART2_BASE

1:
    ldr     w2, [x1, #UART_LSR]
    tst     w2, #UART_LSR_THRE
    b.eq    1b

    str     w0, [x1, #UART_RBR_THR_DLL]

    ret

.size platform_uart_putc, . - platform_uart_putc