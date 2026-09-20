# PowKiddy X55 — FeROS Reference Platform Bring-up

The PowKiddy X55 is the first physical reference platform used to bring
FeROS to bare metal.

The X55 does not define the FeROS architecture.

Rockchip RK3566 mechanisms such as RKNS, the vendor DDR initializer,
memory-mapped peripheral addresses, and the existing boot chain are
platform constraints that FeROS must satisfy when running on this board.

They are not architectural requirements of FeROS.

The purpose of this bring-up is to:

1. Understand the hardware from reset onward.
2. Establish the minimum contract required to execute FeROS code.
3. Replace the existing second-stage bootloader with FeROS Stage 0.
4. Use the resulting knowledge to develop portable FeROS abstractions.
5. Avoid allowing X55/RK3566-specific mechanisms to leak into the
   platform-independent architecture.