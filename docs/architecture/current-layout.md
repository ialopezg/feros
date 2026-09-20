# FeROS — Current Architecture and Bring-up State

> **Close to the metal.**  
> **No magic. Every layer is visible.**

This document represents the current FeROS repository structure, the verified
PowKiddy X55 boot research, and the boundary where FeROS development begins.

---

## 1. Repository Layout

```text
feros/
│
├── arch/
│   └── aarch64/
│       └── boot/
│           └── [FeROS early AArch64 boot code]
│
├── soc/
│   └── rockchip/
│       └── rk3566/
│           └── [RK3566-specific implementation]
│
├── boards/
│   └── powkiddy/
│       └── x55/
│           └── [X55-specific configuration]
│
├── research/
│   └── powkiddy/
│       └── x55/
│           └── boot/
│               ├── x55-boot-area.bin
│               └── x55-boot-area-512k.bin
│
├── docs/
│   ├── architecture/
│   │   └── current-layout.md
│   │
│   ├── hardware/
│   │   ├── powkiddy-x55.md
│   │   └── rk3566-boot.md
│   │
│   ├── developer-guide.md
│   └── engineering-architecture.md
│
├── LICENSE
└── README.md
```

### Layer Responsibilities

| Layer | Responsibility |
|---|---|
| `arch/aarch64/` | ARMv8-A / AArch64 mechanisms independent of a specific SoC |
| `soc/rockchip/rk3566/` | RK3566-specific registers, peripherals and initialization |
| `boards/powkiddy/x55/` | Physical X55 board configuration |
| `research/` | Hardware evidence and forensic captures |
| `docs/` | Verified knowledge, architecture and engineering documentation |

The dependency direction should remain:

```text
Board
  │
  ▼
SoC
  │
  ▼
Architecture
```

The architecture layer must never need to know that a PowKiddy X55 exists.

---

# 2. Physical X55 Research

The original PowKiddy X55 system SD was inspected read-only.

Two forensic captures currently exist:

```text
research/powkiddy/x55/boot/

x55-boot-area.bin
└── first 256 KiB of original system SD

x55-boot-area-512k.bin
└── first 512 KiB of original system SD
```

These files are **research specimens**.

They are not FeROS executables and are not part of the FeROS runtime.

---

# 3. Current X55 Boot Lifecycle

The physical machine currently follows this general boot path:

```text
                         POWER ON
                            │
                            ▼
                  ┌───────────────────┐
                  │   RK3566 BootROM  │
                  │                   │
                  │ Immutable code    │
                  │ inside the SoC    │
                  └─────────┬─────────┘
                            │
                            │ reads boot media
                            ▼
                  ┌───────────────────┐
                  │ Original X55 SD   │
                  │                   │
                  │ LBA 64            │
                  │ byte 0x8000       │
                  └─────────┬─────────┘
                            │
                            ▼
                  ┌───────────────────┐
                  │ RKNS / new-IDB    │
                  │                   │
                  │ boot metadata     │
                  │ descriptors       │
                  │ SHA-256 hashes    │
                  └─────────┬─────────┘
                            │
                  ┌─────────┴─────────┐
                  │                   │
                  ▼                   ▼
        ┌───────────────────┐  ┌───────────────────┐
        │ Payload #1        │  │ Payload #2        │
        │                   │  │                   │
        │ DDR initializer   │  │ Bootloader stage  │
        │                   │  │                   │
        │ 55,296 bytes      │  │ 241,664 bytes     │
        │ SHA-256 verified  │  │ SHA-256 verified  │
        └─────────┬─────────┘  └─────────┬─────────┘
                  │                      │
                  └──── DDR ready ──────►│
                                         │
                                         ▼
                                 Later boot stages
                                         │
                                         ▼
                                    JELOS/Linux
```

---

# 4. What We Have Verified

The following facts come from the physical X55 and its original system SD.

### Hardware

```text
SoC          Rockchip RK3566
CPU          4 × ARM Cortex-A55
ISA          ARMv8-A / AArch64
RAM          ~2 GiB
Board model  Powkiddy x55
```

### Early UART

The running X55 exposes its Linux early console as:

```text
UART2
MMIO: 0xFE660000
```

The physical UART pinout and electrical interface still require verification
before connecting external serial hardware.

### Boot media

The original system SD is exposed by the running X55 as:

```text
/dev/mmcblk0
```

### Rockchip boot container

The original SD contains:

```text
LBA 64
    │
    └── byte offset 0x8000
            │
            ▼
           RKNS
```

The RKNS header and its payload descriptors were decoded from the captured
media.

The header integrity hash and both payload hashes have been independently
validated.

---

# 5. FeROS First Bring-up Target

FeROS does **not** initially attempt to replace every component at once.

The first controlled experiment will retain the known-working DDR
initialization component while replacing the following bootloader stage with
FeROS code.

```text
                         POWER ON
                            │
                            ▼
                  ┌───────────────────┐
                  │   RK3566 BootROM  │
                  │                   │
                  │     HARDWARE      │
                  └─────────┬─────────┘
                            │
                            ▼
                  ┌───────────────────┐
                  │       RKNS        │
                  │                   │
                  │ BootROM contract  │
                  └─────────┬─────────┘
                            │
                            ▼
                  ┌───────────────────┐
                  │ DDR initializer   │
                  │                   │
                  │ Temporarily use   │
                  │ known-good code   │
                  └─────────┬─────────┘
                            │
                            ▼
               ╔═════════════════════════╗
               ║      FeROS Stage 0      ║
               ║                         ║
               ║        OUR CODE         ║
               ║                         ║
               ║  AArch64 bare metal     ║
               ╚════════════╤════════════╝
                            │
                            ▼
                  ┌───────────────────┐
                  │       UART2       │
                  │    0xFE660000     │
                  └─────────┬─────────┘
                            │
                            ▼

                     FeROS v0.0.1
                  Board: PowKiddy X55
                     SoC: RK3566
                   FeROS booting...
```

---

# 6. Ownership Boundary

On the X55, the immutable RK3566 BootROM is treated as part of the hardware.

```text
┌─────────────────────────────────────┐
│             HARDWARE                │
│                                     │
│ RK3566                              │
│ └── immutable BootROM               │
└─────────────────┬───────────────────┘
                  │
                  │ hardware/software boundary
                  ▼
┌─────────────────────────────────────┐
│              FEROS                  │
│                                     │
│ Boot container                      │
│ Early initialization                │
│ Stage 0                             │
│ Kernel                              │
│ Drivers                             │
│ Runtime                             │
│ SDK                                 │
└─────────────────────────────────────┘
```

The initial X55 bring-up may temporarily depend on Rockchip's DDR
initialization binary.

That is a bring-up dependency, not an architectural requirement of FeROS.

---

# 7. Current Position

We have completed the first boot-media reconnaissance:

```text
[✓] Identify X55 SoC
[✓] Identify CPU architecture
[✓] Identify system SD
[✓] Locate Rockchip boot container
[✓] Identify RKNS/new-IDB
[✓] Decode RKNS payload descriptors
[✓] Verify RKNS header SHA-256
[✓] Identify DDR payload
[✓] Verify DDR payload SHA-256
[✓] Identify second bootloader payload
[✓] Verify second payload SHA-256

[ ] Determine Payload #2 load address
[ ] Determine CPU state at handoff
[ ] Determine execution level
[ ] Determine MMU/cache state
[ ] Establish initial stack strategy
[ ] Implement FeROS AArch64 entry point
[ ] Implement minimal RK3566 UART
[ ] Build FeROS Stage 0
[ ] Construct experimental RKNS image
[ ] Write image to dedicated laboratory SD
[ ] Boot physical X55
[ ] Receive first FeROS UART output
```

---

# 8. Immediate Engineering Objective

We are here:

```text
Existing RKNS
     │
     ├── DDR initializer ─────────────── verified
     │
     └── Payload #2
             │
             │ determine exact handoff contract
             ▼
       ┌──────────────┐
       │ FeROS Stage 0│
       └──────┬───────┘
              │
              ▼
            UART
```

Before implementing:

```text
arch/aarch64/boot/start.S
```

we must establish the contract under which the RK3566 boot process transfers
execution to the second payload.

Specifically:

```text
load address
entry address
exception level
register state
stack state
MMU state
cache state
```

Once those are established, FeROS can execute its **first instruction**.

---

**FeROS**

> Close to the metal.  
> No magic. Every layer is visible.