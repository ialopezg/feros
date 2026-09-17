# RK3566 Boot Architecture

## Purpose

This document describes the boot architecture relevant to FeROS on the
Rockchip RK3566.

The PowKiddy X55 is the first development board, but the boot architecture
must remain separated into architecture, SoC, and board-specific concerns.

FeROS must not depend on the PowKiddy X55 as its permanent hardware
platform.

---

## Hardware Layers

```text
FeROS
  |
  +-- Architecture: AArch64
  |
  +-- SoC: Rockchip RK3566
  |
  +-- Board
      |
      +-- PowKiddy X55          Development platform
      |
      `-- Future FeROS board    Custom hardware
```

The RK3566 boot mechanism belongs primarily to the SoC layer.

Board-specific concerns such as DRAM topology, GPIO routing, display,
controls, power management, and peripheral wiring belong to the board
layer.

---

## Initial Boot Model

The current working model is:

```text
Power-on
   |
   v
+---------------------------+
| RK3566 BootROM            |
|                           |
| Immutable code in SoC     |
+-------------+-------------+
              |
              | Boot media discovery
              v
+---------------------------+
| IDB / first-stage image   |
|                           |
| DDR initialization        |
| First-level loader        |
+-------------+-------------+
              |
              | DRAM available
              v
+---------------------------+
| FeROS early boot          |
|                           |
| AArch64 entry             |
+-------------+-------------+
              |
              v
+---------------------------+
| FeROS kernel              |
+---------------------------+
```

This model is intentionally provisional.

The exact transition between the Rockchip BootROM, DDR initialization,
first-stage loader, and FeROS code must be verified before implementation.

---

## SD Boot Location

Rockchip boot images for SD media are conventionally written beginning at
logical block address 64.

Assuming 512-byte sectors:

```text
LBA 64
64 * 512 bytes
= 32768 bytes
= 32 KiB
```

Therefore the first 32 KiB of the SD device precede the Rockchip boot image.

Example only:

```text
microSD

LBA 0
+----------------------------------+
| Reserved / partition metadata    |
|                                  |
| 32 KiB                           |
+----------------------------------+
LBA 64
+----------------------------------+
| Rockchip boot image              |
+----------------------------------+
|                                  |
| Additional boot components       |
|                                  |
+----------------------------------+
```

No FeROS SD image shall be written until the complete RK3566 image layout
has been verified.

---

## DDR Initialization

DRAM cannot be assumed to be usable immediately after reset.

Rockchip provides RK3566 DDR initialization binaries supporting multiple
DRAM configurations, including LPDDR4 and LPDDR4X.

For the initial FeROS bring-up, the current strategy is:

```text
Rockchip DDR initialization
             |
             v
       DRAM available
             |
             v
        FeROS code
```

The Rockchip DDR initialization component is considered a temporary
bootstrap dependency.

It is not part of the FeROS kernel.

Whether FeROS eventually replaces this component is a separate engineering
decision.

---

## IDB Loader

Rockchip tooling defines an IDB loader as a boot image containing:

```text
+--------------------------+
| DDR initialization       |
+--------------------------+
| First-level loader       |
+--------------------------+
```

For FeROS, the desired long-term boundary is:

```text
+--------------------------+
| Required SoC bootstrap   |
| DDR initialization       |
+--------------------------+
             |
             | earliest practical handoff
             v
+--------------------------+
| FeROS                    |
+--------------------------+
```

The objective is to take control as early as practical while maintaining a
reliable and reproducible boot process.

---

## First FeROS Milestone

The first successful FeROS execution does not require:

- Display support
- GPU support
- Filesystem support
- Audio
- Input devices
- Networking
- RetroArch
- Linux
- A graphical interface

The first milestone is simply:

```text
RK3566 BootROM
      |
      v
DDR initialization
      |
      v
FeROS entry
      |
      v
UART initialization
      |
      v
"FeROS booting..."
```

Receiving that message from the physical device proves that FeROS code is
executing on the RK3566.

---

## Open Questions

The following must be established experimentally or from authoritative
documentation before the first boot image is produced:

1. Exact RK3566 BootROM SD boot contract.
2. Exact IDB image format required by RK3566.
3. SRAM available before DDR initialization.
4. Execution address of the first-stage payload.
5. CPU exception level at FeROS handoff.
6. MMU and cache state at FeROS handoff.
7. Required clock initialization before FeROS execution.
8. Exact DDR configuration used by the PowKiddy X55.
9. UART controller used for early debugging.
10. UART MMIO base address.
11. UART pinmux configuration.
12. Physical UART pads accessible on the X55.
13. Electrical voltage level of those UART pads.
14. SD controller state when control reaches FeROS.
15. Minimum Rockchip bootstrap component that FeROS must retain.

These questions form the RK3566 bring-up investigation backlog.

---

## Design Rule

No hardware address, register value, memory location, boot offset, clock
frequency, or pin assignment shall enter FeROS source code merely because
it worked on another RK3566 board.

Every such value must be traceable to:

1. RK3566 architecture/technical documentation,
2. PowKiddy X55 hardware evidence,
3. trusted reference implementation, or
4. direct measurement on the target hardware.

This rule becomes especially important when FeROS moves from the PowKiddy
X55 to custom hardware.
