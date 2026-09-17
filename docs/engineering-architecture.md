# FeROS - Engineering Architecture

## Purpose

This document defines the current technical architecture and engineering
boundaries of **FeROS (Ferrite Retro Operating System)**.

FeROS is an independent, performance-first operating system being built from
scratch for retro handhelds and embedded gaming hardware.

The project originally began as **FerroOS**, using Docker, Linux, Buildroot,
RetroArch, and a simulated frontend. That implementation remains part of the
Git history, but it no longer defines the active architecture.

> **Close to the metal.**

---

## 1. Architectural Objective

FeROS intends to control the software stack from the earliest practical
post-ROM execution stage through the kernel, hardware abstraction, drivers,
runtime, system APIs, and eventually the gaming environment.

The high-level direction is:

```text
Immutable SoC BootROM
        |
        v
required SoC bootstrap / DDR initialization
        |
        v
FeROS early boot
        |
        v
FeROS kernel
        |
        v
HAL / drivers
        |
        v
system services / runtime
        |
        v
applications / games
```

The immutable BootROM is part of the silicon and therefore outside FeROS.

During early RK3566 bring-up, the minimum vendor component required to
initialize hardware such as DRAM may also remain outside the FeROS kernel.
This is a bootstrap dependency, not the target runtime architecture.

---

## 2. Hardware Abstraction Model

The PowKiddy X55 is the first physical development board, not the definition
of FeROS.

```text
                         GENERIC

                    Application / Game
                           |
                           v
                       FeROS API
                           |
                           v
                         Kernel
                           |
                           v
                          HAL

                 ----- hardware boundary -----

                           |
                           v
                        AArch64
                           |
                           v
                         RK3566
                           |
                           v
                     PowKiddy X55
```

Hardware specificity increases downward. Portability increases upward.

The long-term model must also allow:

```text
FeROS
  |
  +-- Architecture
  |     `-- AArch64
  |
  +-- SoC
  |     `-- Rockchip RK3566
  |
  +-- Board
        +-- PowKiddy X55
        `-- Future custom FeROS hardware
```

This separation is essential because the project ultimately intends to move
beyond an existing handheld and into custom PCBs, controls, enclosures, and
purpose-built FeROS devices.

---

## 3. Architectural Layers

### 3.1 Architecture Layer

Location:

```text
arch/aarch64/
```

Responsibilities may include:

- earliest AArch64 entry,
- stack establishment,
- exception vectors,
- exception-level handling,
- CPU system registers,
- MMU primitives,
- page-table mechanics,
- cache maintenance,
- barriers and atomic primitives,
- low-level context switching,
- architecture timers where appropriate.

This code should be reusable across AArch64 platforms whenever the behavior is
defined by the architecture rather than the RK3566.

### 3.2 SoC Layer

Location:

```text
soc/rockchip/rk3566/
```

Responsibilities may include:

- RK3566 memory map,
- interrupt-controller integration,
- clock and reset controllers,
- UART controllers,
- GPIO,
- pin control,
- SD/MMC,
- USB,
- display subsystem,
- power domains,
- SoC-specific timers,
- integrated peripheral initialization.

A different RK3566 board should be able to reuse this layer.

### 3.3 Board Layer

Location:

```text
boards/powkiddy/x55/
```

Responsibilities include physical facts about the X55, such as:

- DRAM topology and board configuration,
- display panel and timings,
- GPIO assignments,
- buttons and analog controls,
- regulator wiring,
- storage wiring,
- audio routing,
- battery and power circuitry,
- Wi-Fi / Bluetooth devices,
- debug UART routing and accessible pads.

The generic kernel must not contain X55-specific conditionals.

### 3.4 Kernel Layer

Location:

```text
kernel/
```

The kernel should contain portable operating-system mechanisms such as:

- physical memory management,
- virtual memory abstractions,
- scheduling,
- synchronization,
- task/process abstractions,
- IPC,
- generic interrupt interfaces,
- logging,
- filesystem interfaces,
- system calls,
- executable loading,
- generic input, graphics, and audio interfaces.

The kernel should know about abstractions, not individual handheld products.

### 3.5 Drivers

Location:

```text
drivers/
```

Drivers should bridge generic interfaces with architecture-, SoC-, or
device-specific implementations without collapsing those boundaries.

Likely future categories include:

```text
drivers/
├── block/
├── display/
├── input/
├── audio/
├── network/
└── usb/
```

These directories should appear only when actual implementation requires them.

### 3.6 Runtime and System APIs

Later stages will introduce:

```text
runtime/
sdk/
```

These layers will define the application model, executable/runtime support,
system APIs, graphics/audio/input APIs, libraries, and developer-facing SDK.

FeROS must first provide the operating-system primitives on which such a
runtime can safely depend.

---

## 4. Source Architecture

The current direction is:

```text
feros/
├── arch/
│   └── aarch64/
│       └── boot/
│
├── soc/
│   └── rockchip/
│       └── rk3566/
│
├── boards/
│   └── powkiddy/
│       └── x55/
│
├── docs/
│   └── hardware/
│
├── kernel/       # introduced as generic kernel requirements emerge
├── drivers/      # introduced as driver abstractions emerge
├── runtime/      # later-stage runtime
├── sdk/          # later-stage developer SDK
├── tools/        # build, image, inspection, and development tooling
└── examples/     # later, when stable APIs exist
```

The tree must evolve from real requirements. Empty speculative subsystems
should not be created merely to make the repository look complete.

---

## 5. Boot Architecture

The current RK3566 bring-up model is:

```text
Power On
   |
   v
RK3566 BootROM
   |
   v
boot-media discovery
   |
   v
required first-stage bootstrap
   |
   v
DDR initialization
   |
   v
FeROS early entry
   |
   v
controlled AArch64 execution
   |
   v
FeROS kernel
```

This model remains provisional until the RK3566 BootROM contract and handoff
state are fully verified.

Detailed boot research belongs in:

```text
docs/hardware/rk3566-boot.md
```

The implementation must not guess:

- load addresses,
- execution addresses,
- SRAM availability,
- exception level,
- MMU/cache state,
- clock state,
- UART MMIO addresses,
- pinmux values,
- SD offsets,
- DDR configuration.

Those values must be established from evidence before becoming source-code
constants.

---

## 6. First Physical Bring-up Milestone

The first milestone is deliberately tiny:

```text
Power On
   |
   v
RK3566 BootROM
   |
   v
required bootstrap / DDR initialization
   |
   v
FeROS entry
   |
   v
establish required CPU state / stack
   |
   v
initialize verified debug UART
   |
   v
FeROS v0.0.1
Board: PowKiddy X55
SoC: RK3566
FeROS booting...
```

This milestone requires no:

- Linux runtime,
- Buildroot runtime,
- RetroArch,
- filesystem,
- graphical interface,
- display driver,
- audio,
- input subsystem,
- networking.

Observable serial output from code owned by FeROS is sufficient proof of the
first successful bare-metal bring-up.

---

## 7. Language and Runtime Model

Initial implementation should predominantly use **C**, with **AArch64
assembly** restricted to code that genuinely requires direct architectural
control.

### C

Expected uses:

- kernel mechanisms,
- memory management,
- scheduler,
- HAL,
- drivers,
- filesystems,
- libraries,
- runtime implementation.

### AArch64 Assembly

Expected uses:

- earliest entry,
- initial stack,
- exception vectors,
- CPU system-register operations,
- context switching,
- selected low-level primitives.

The initial environment is freestanding.

FeROS cannot assume the existence of:

- libc,
- `printf`,
- `malloc`,
- files,
- processes,
- threads,
- another operating system,
- a language runtime.

Those facilities must be implemented or deliberately introduced by FeROS.

---

## 8. Build Architecture

The early build pipeline should become:

```text
AArch64 assembly + freestanding C
                 |
                 v
             objects
                 |
                 v
           linker script
                 |
                 v
             FeROS ELF
                 |
          +------+------+
          |             |
          v             v
   symbol/debug      raw binary
     inspection          |
                         v
                 RK3566 boot image
                         |
                         v
                    microSD
```

The ELF file should remain a first-class build artifact for symbol and section
inspection even when a packaged/raw image is ultimately written to the boot
medium.

The linker address and image format must follow the verified RK3566 boot
contract rather than being chosen arbitrarily.

---

## 9. Debug Architecture

UART is the preferred first diagnostic channel because it can provide
visibility before display, USB, networking, storage, or a filesystem exists.

The earliest useful debugging hierarchy is:

```text
boot-stage markers
        |
        v
low-level UART output
        |
        v
kernel logging
        |
        v
structured diagnostics
```

A failure that cannot be observed is expensive to diagnose. Debuggability is
therefore an architectural requirement, not an afterthought.

---

## 10. Memory Architecture

Memory development should proceed incrementally:

```text
known physical memory map
          |
          v
early/static allocations
          |
          v
physical page allocator
          |
          v
MMU / page tables
          |
          v
virtual address spaces
          |
          v
task/process memory
```

DRAM must not be assumed available immediately after reset. The boundary
between vendor DDR initialization and FeROS memory ownership must remain
explicit.

---

## 11. Interrupts, Exceptions, and Scheduling

The kernel foundation will eventually require:

```text
AArch64 exception vectors
          |
          v
interrupt-controller support
          |
          v
system timer
          |
          v
scheduler
          |
          v
tasks / synchronization
```

Exception handling should precede complex subsystems so that faults become
diagnosable rather than silent resets or hangs.

---

## 12. Storage and Filesystems

Early FeROS images may operate without a conventional filesystem.

The dedicated development microSD may initially contain boot components at
known raw locations.

Later architecture should separate:

```text
storage controller
       |
       v
block-device interface
       |
       v
partition handling
       |
       v
filesystem
       |
       v
system / application / user data
```

Raw media layout is a boot concern. Filesystem semantics belong above the
block-device layer.

---

## 13. Graphics and Gaming Stack

Graphics should evolve in stages:

```text
display-controller bring-up
          |
          v
framebuffer
          |
          v
software rendering
          |
          v
graphics abstraction
          |
          v
GPU investigation / acceleration
```

The Mali-G52 GPU is a later-stage target. Initial FeROS existence must not
depend on GPU acceleration.

The gaming environment should eventually sit above stable FeROS APIs rather
than define the kernel architecture.

---

## 14. Linux as a Reference Instrument

The existing X55 Linux environment may be used for hardware reconnaissance.

It can provide evidence about:

- device tree,
- memory map,
- interrupts,
- GPIO,
- clocks,
- regulators,
- input devices,
- display,
- storage,
- audio,
- Wi-Fi,
- Bluetooth,
- existing driver choices.

The relationship is:

```text
Linux reference environment
          |
          v
hardware evidence
          |
          v
FeROS documentation
          |
          v
independent FeROS implementation
```

Linux is not the FeROS runtime.

---

## 15. Custom Hardware Direction

The architecture must anticipate a future FeROS handheld designed by the
project itself.

That path may include:

```text
hardware requirements
        |
        v
SoC / component selection
        |
        v
schematic design
        |
        v
PCB design and fabrication
        |
        v
assembly / soldering
        |
        v
enclosure design and fabrication
        |
        v
FeROS board-support package
        |
        v
FeROS on purpose-built hardware
```

The X55 exists to teach us the complete hardware/software boundary before we
control both sides of that boundary ourselves.

---

## 16. Engineering Evidence Rule

No hardware address, register value, memory location, boot offset, clock
frequency, pin assignment, or electrical assumption should enter FeROS merely
because it worked on another board.

Every hardware-specific value must be traceable to one or more of:

1. architecture or SoC technical documentation,
2. target-board hardware evidence,
3. a trusted reference implementation,
4. direct measurement on the physical target.

When evidence is incomplete, the documentation should say so explicitly.

---

## 17. Development Progression

### Stage 0 - Transition

- Preserve FerroOS history in Git.
- Remove the active Docker/Linux simulation architecture.
- Establish FeROS identity and architectural boundaries.
- Document the X55 and RK3566 boot investigation.

### Stage 1 - Bare-Metal Bring-up

- Verify RK3566 BootROM SD contract.
- Verify first-stage / IDB image format.
- Establish minimum DDR/bootstrap dependency.
- Determine FeROS load address and handoff CPU state.
- Verify X55 debug UART.
- Build the first freestanding AArch64 executable.
- Boot from the dedicated development microSD.
- Produce observable FeROS UART output.

### Stage 2 - Kernel Foundation

- Exceptions.
- Interrupt controller.
- Timer.
- Physical memory allocator.
- MMU and virtual memory.
- Basic allocator.
- Scheduler and synchronization.
- Kernel logging.

### Stage 3 - X55 Enablement

- SD/MMC.
- Input.
- Display/framebuffer.
- Audio.
- USB.
- Battery/power.
- Connectivity investigation.

### Stage 4 - Runtime and Gaming Platform

- Filesystems.
- Executable/application model.
- System APIs.
- SDK.
- Graphics/audio/input APIs.
- Gaming runtime.
- Native frontend.

### Stage 5 - Purpose-Built FeROS Hardware

- Hardware requirements.
- Component selection.
- Custom PCB.
- Prototype assembly.
- Custom enclosure.
- Board-support package.
- FeROS boot on project-designed hardware.

---

## 18. Architectural Principle

FeROS should never become synonymous with PowKiddy X55 firmware.

The intended relationship is:

```text
FeROS + architecture + SoC + board
```

not:

```text
FeROS == PowKiddy X55
```

The X55 is the first machine on which we prove the architecture.

The architecture succeeds when FeROS can move to another board - ultimately
one we designed ourselves - without rewriting the operating system.
