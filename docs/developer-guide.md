# FeROS — Developer Guide

This guide describes the current development workflow for **FeROS
(Ferrite Retro Operating System)**.

FeROS is no longer developed as a Docker-based simulation or as a Linux /
Buildroot distribution. It is an independent operating-system project whose
first physical bring-up target is the **PowKiddy X55**, based on the
**Rockchip RK3566**.

> **Close to the metal.**

The immediate engineering objective is not to simulate a frontend. It is to
produce the smallest verified AArch64 image that can reach observable FeROS
code on the physical RK3566.

---

## 1. Development Model

The current hardware boundary is:

```text
FeROS
  |
  +-- Architecture: AArch64 / ARMv8-A
  |
  +-- SoC: Rockchip RK3566
  |
  +-- Board: PowKiddy X55
```

The X55 is the first development board and hardware laboratory. It must not
become an implicit dependency of the generic FeROS kernel.

The long-term goal is to support additional boards and eventually custom
FeROS handheld hardware.

---

## 2. Current Repository Structure

The active source architecture begins with explicit hardware boundaries:

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
│       ├── powkiddy-x55.md
│       └── rk3566-boot.md
│
├── LICENSE
└── README.md
```

Additional directories such as `kernel/`, `drivers/`, `runtime/`, and `tools/`
should be introduced as concrete engineering requirements emerge rather than
being populated speculatively.

### Responsibilities

- `arch/aarch64/` contains behavior determined by the AArch64 architecture.
- `soc/rockchip/rk3566/` contains behavior determined by the RK3566 SoC.
- `boards/powkiddy/x55/` contains physical X55 wiring and board configuration.
- `kernel/` will contain portable operating-system mechanisms and must not
  depend directly on the X55.

---

## 3. Historical Docker Environment

The original FerroOS project used Docker to simulate an init sequence and
frontend environment.

That workflow has been retired.

The following components are no longer part of the active FeROS architecture:

```text
Dockerfile
init.sh
frontend/init.sh
run.sh
roms/
system/
```

Their history remains available through Git.

Do not recreate the Docker simulation as part of the bare-metal bring-up. Linux
or containers may still be useful as external development tools, but they are
not the FeROS runtime.

---

## 4. Host Development Environment

The initial host environment is macOS.

Early development will require tools in several categories:

```text
editor / IDE
     |
     v
AArch64 compiler + assembler
     |
     v
linker
     |
     v
binary inspection tools
     |
     v
Rockchip image/bootstrap tooling
     |
     v
raw microSD writer
     |
     v
serial terminal
```

Exact toolchain packages and versions should be recorded only when they are
selected and verified for the build.

The FeROS build must be reproducible. Toolchain assumptions should eventually
be encoded in build scripts rather than depending on undocumented workstation
state.

---

## 5. Implementation Languages

The initial implementation direction is:

- **C** for most kernel, SoC, board, HAL, and driver implementation.
- **AArch64 assembly** only where direct architectural control requires it.

Assembly is expected for responsibilities such as:

- earliest execution entry,
- initial stack establishment,
- exception vectors,
- special CPU register operations,
- low-level context switching.

Early C code is **freestanding**.

It must not assume the existence of:

- libc,
- `printf`,
- `malloc`,
- files,
- processes,
- threads,
- an operating-system host,
- a runtime environment.

Those facilities either have to be implemented by FeROS or deliberately
introduced later.

---

## 6. Bring-up Boot Model

The current working model is:

```text
Power On
   |
   v
RK3566 BootROM
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
AArch64 initialization
   |
   v
verified debug UART
   |
   v
FeROS kernel bring-up
```

This model is intentionally subject to refinement as the RK3566 boot contract
is verified.

The immutable BootROM and any minimum vendor component required to initialize
DRAM are outside the FeROS kernel boundary.

For initial bring-up, FeROS may temporarily depend on Rockchip-provided DDR
initialization. That does not make Rockchip code part of FeROS.

---

## 7. First Milestone

The first successful FeROS build does not need a gaming frontend.

It does not need:

- Linux,
- Buildroot,
- RetroArch,
- a filesystem,
- graphics,
- audio,
- input,
- networking,
- USB,
- process management.

The first physical milestone is:

```text
Power On
   |
   v
RK3566 bootstrap succeeds
   |
   v
FeROS code executes
   |
   v
UART is initialized
   |
   v
FeROS booting...
```

A serial message produced by our code is enough to prove that FeROS has taken
control at the intended stage.

---

## 8. Before Writing Boot Code

Do not introduce hardware constants based only on examples from another RK3566
board.

Before the first FeROS boot image is considered valid, investigate and record:

1. RK3566 BootROM SD boot contract.
2. Required IDB / first-stage image format.
3. SRAM available before DRAM initialization.
4. Execution address for the first-stage payload.
5. CPU exception level at handoff.
6. MMU and cache state at handoff.
7. Clock state required by FeROS.
8. X55 DRAM configuration.
9. Debug UART controller.
10. UART MMIO base address.
11. UART pinmux.
12. Accessible X55 UART pads.
13. UART electrical voltage.
14. SD controller state at handoff.
15. Minimum bootstrap component that must remain outside FeROS.

The detailed investigation belongs in:

```text
docs/hardware/rk3566-boot.md
```

---

## 9. Development microSD

A dedicated **32 GB microSD** is the current destructive-development medium.

The original PowKiddy system card should remain untouched for recovery and
hardware reconnaissance.

On macOS, always identify the card again before a raw-device operation:

```bash
diskutil list
```

A device identifier such as:

```text
/dev/disk6
```

is temporary and may change after reconnection or reboot.

Never encode that identifier into a permanent script.

Before writing a raw image, the selected device must be verified by capacity,
removability, interface, and expected media identity.

---

## 10. Raw Device Writes

`dd` can copy image bytes directly to a block device.

Conceptually:

```text
FeROS / bootstrap image
          |
          v
         dd
          |
          v
    raw microSD sectors
```

A command such as:

```bash
sudo dd if=<image> of=/dev/rdiskN ...
```

can destroy the contents of the selected device.

Therefore:

1. run `diskutil list`,
2. identify the development microSD,
3. verify the device,
4. unmount the whole disk,
5. verify the identifier again,
6. only then perform the raw write.

No FeROS documentation should instruct a developer to copy a destructive
command with a fixed `/dev/diskN` identifier.

The exact RK3566 image layout and offsets must be verified before the first
FeROS image is written.

---

## 11. Hardware Reconnaissance

The existing Linux environment on the X55 can be used as an engineering
instrument.

Useful information may include:

- device tree,
- memory map,
- clocks,
- regulators,
- GPIO assignments,
- interrupt assignments,
- storage controllers,
- display configuration,
- input devices,
- audio hardware,
- Wi-Fi and Bluetooth devices,
- kernel driver selection.

The intended workflow is:

```text
Existing Linux
      |
      v
hardware reconnaissance
      |
      v
verified documentation
      |
      v
independent FeROS implementation
```

Linux is evidence and a diagnostic environment, not a runtime dependency.

---

## 12. Build Pipeline

The intended early build pipeline is:

```text
AArch64 assembly + freestanding C
                 |
                 v
           object files
                 |
                 v
          linker script
                 |
                 v
            FeROS ELF
                 |
        +--------+--------+
        |                 |
        v                 v
  inspection/debug    raw binary
                          |
                          v
                 RK3566 boot image
                          |
                          v
                     microSD
```

The ELF artifact should be retained because its symbols and sections are useful
for debugging and inspection even when the boot medium ultimately receives a
different binary/image format.

The precise linker address and image packaging must not be selected until the
RK3566 handoff contract is established.

---

## 13. Debugging Strategy

Early OS development requires observable failure modes.

The initial debugging priority is:

```text
UART
  |
  +-- earliest diagnostic output
  |
  +-- boot-stage markers
  |
  +-- panic/error output
  |
  `-- hardware initialization traces
```

Display output is not an appropriate dependency for the first milestone
because it requires substantially more hardware initialization.

Once UART is verified, FeROS should establish a tiny low-level logging path
before higher-level subsystems are introduced.

---

## 14. Git Workflow

The bare-metal transition currently develops from:

```text
feature/bare-metal-bringup
```

Keep commits small and architectural.

Prefer commits that establish one verifiable concept at a time, for example:

```text
docs(rk3566): document verified boot contract
build(aarch64): add freestanding toolchain
feat(boot): add initial AArch64 entry point
feat(rk3566): add early UART support
```

Avoid combining unrelated documentation, build-system, driver, and kernel
changes into a single bring-up commit.

Do not commit generated build artifacts unless the repository explicitly
defines them as versioned deliverables.

---

## 15. Engineering Rule

No hardware address, register value, memory location, boot offset, clock
frequency, or pin assignment should enter FeROS source code merely because it
worked on another board.

Every hardware-specific value should be traceable to one or more of:

1. architecture or SoC technical documentation,
2. PowKiddy X55 hardware evidence,
3. a trusted reference implementation,
4. direct measurement on the target hardware.

This discipline matters on the X55 and becomes essential when FeROS moves to
its own PCB.

---

## 16. Next Development Step

The immediate task is not to implement the kernel.

It is to close the RK3566 boot investigation far enough to define a trustworthy
contract for the first FeROS executable:

```text
Where is it loaded?
        |
At what address does it execute?
        |
What memory is available?
        |
What CPU state exists?
        |
What bootstrap has already run?
        |
How can we prove execution?
```

Once those answers are verified, the first `arch/aarch64/boot/start.S`, linker
script, and freestanding build can be created from known constraints rather
than assumptions.
