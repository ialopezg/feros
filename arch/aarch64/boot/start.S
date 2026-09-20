/*
 * FeROS AArch64 entry point.
 *
 * This is the first FeROS code executed by the RK3566 bring-up path.
 * No runtime environment is assumed.
 */

 .section .text.boot
 .global _start

 _start:
     /*
      * Keep the first experiment intentionally minimal.
      *
      * We do not touch the stack, MMU, caches, exception levels,
      * or DRAM here yet.
      */

 1:
     wfe
     b 1b

.size _start, . - _start