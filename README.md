# FeROS

**Ferrite Retro Operating System**

[![License: Apache 2.0](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Build](https://img.shields.io/github/actions/workflow/status/ialopezg/feros/ci.yml?branch=main)](https://github.com/ialopezg/feros/actions)
[![Architecture](https://img.shields.io/badge/architecture-AArch64-brightgreen)](docs/engineering-architecture.md)
[![Target](https://img.shields.io/badge/bring--up-PowKiddy%20X55%20%7C%20RK3566-orange)](docs/hardware/powkiddy-x55.md)

**FeROS** is a performance-first independent operating system being built from
scratch for retro handhelds and embedded gaming hardware.

The PowKiddy X55 is the first physical development platform. It is a hardware
laboratory for FeROS, not the permanent definition of the operating system.

> **Close to the metal.**
>
> **No magic. Every layer is visible.**

---

## Project Identity

The name **FeROS** expresses the project's three core ideas:

- **Fe** — Ferrite, with an additional association to iron (`Fe`), hardware,
  physicality, and low-level engineering.
- **R** — Retro.
- **OS** — Operating System.

FeROS began as **FerroOS**, a Linux/Docker-based experiment. That original
simulation is preserved as `v0.0.1 — Unborn`.

With `v0.1.0`, the project transitioned into an independent bare-metal
operating-system effort.

---

## Project Philosophy

- Hardware-first.
- Predictable behavior over unnecessary abstraction.
- Minimal magic; important layers should remain observable.
- Performance and debuggability are design concerns from the beginning.
- Generic kernel code must remain independent of individual handheld models.
- Architecture-, SoC-, and board-specific responsibilities must remain separated.
- Hardware constants must be traceable to evidence.
- Documentation is part of the engineering product.
- Linux may be used for hardware reconnaissance, but it is not the FeROS runtime.

---

## Architecture

FeROS separates portable operating-system code from architecture, SoC, and
board-specific implementation:

```text
Application / Game
        |
    FeROS API
        |
      Kernel
        |
     Drivers
        |
---------------- hardware boundary ----------------
        |
     AArch64
        |
 Rockchip RK3566
        |
 PowKiddy X55
```

> We learn from the X55. We port FeROS to the X55. We do not design FeROS
> around the X55.

Current source boundaries:

```text
feros/
├── arch/
│   └── aarch64/
│       └── boot/
├── soc/
│   ├── rockchip/
│   │   └── rk3566/
│   └── allwinner/
│       └── a133p/
├── boards/
│   ├── powkiddy/
│   │   └── x55/
│   └── trimui/
│       └── smart-pro/
├── kernel/
├── drivers/
├── runtime/
├── sdk/
├── tools/
├── docs/
├── research/
├── Makefile
├── LICENSE
└── README.md
```

The TrimUI Smart Pro / Allwinner A133P paths reserve architectural boundaries
for future investigation. They do not represent implemented hardware support.

---

## Current Bring-up State

The active hardware target is:

```text
Architecture : AArch64 / ARMv8-A
SoC          : Rockchip RK3566
Board        : PowKiddy X55
```

Investigation of the original X55 boot media established the early boot model:

```text
Power
  |
  v
RK3566 BootROM
  |
  v
Rockchip RKNS / new-IDB
  |
  +-- DDR initialization
  |
  v
early executable stage
  |
  v
FeROS Stage 0
```

FeROS contains its first AArch64 entry point and an RK3566 early UART transmit
primitive.

The immediate milestone remains observable execution of FeROS-owned code on
the physical X55.

---

## Building FeROS

FeROS uses a small, explicit Make-based bootstrap build.

The default GNU bare-metal toolchain prefix is:

```text
aarch64-elf-
```

Build:

```bash
make
```

Inspect the generated AArch64 objects:

```bash
make inspect
```

Clean generated artifacts:

```bash
make clean
```

The cross-toolchain prefix can be overridden when required:

```bash
make CROSS_COMPILE=aarch64-linux-gnu-
```

CI invokes the same repository-owned build definition used during development.

Current artifacts are relocatable AArch64 objects under `build/`, mirroring the
source hierarchy. A final linked FeROS ELF and raw boot image are intentionally
not produced until the RK3566 execution-address and handoff contract are
established.

---

## Implementation Direction

The initial implementation uses:

- **C** for kernel, platform, runtime, and driver code as those layers emerge.
- **AArch64 assembly** where direct architectural control is required.

Early FeROS is freestanding. It cannot assume libc, `printf`, `malloc`,
processes, files, or another operating system.

---

## Documentation

Current engineering references:

- [`docs/architecture/current-layout.md`](docs/architecture/current-layout.md)
- [`docs/platforms/powkiddy-x55-bringup.md`](docs/platforms/powkiddy-x55-bringup.md)
- [`docs/hardware/powkiddy-x55.md`](docs/hardware/powkiddy-x55.md)
- [`docs/hardware/rk3566-boot.md`](docs/hardware/rk3566-boot.md)
- [`docs/engineering-architecture.md`](docs/engineering-architecture.md)
- [`docs/developer-guide.md`](docs/developer-guide.md)

Documentation should record not only what works, but why a design exists and
which hardware evidence supports it.

---

## Development Roadmap

### Foundation

- [x] Preserve the original FerroOS history.
- [x] Establish FeROS as a bare-metal operating-system project.
- [x] Establish architecture, SoC, and board boundaries.
- [x] Establish the PowKiddy X55 / RK3566 as the first bring-up platform.
- [x] Preserve the original X55 boot-area captures.
- [x] Identify and validate the RKNS/new-IDB structure.
- [x] Identify the DDR initialization and SPL payload boundaries.
- [x] Add the first AArch64 FeROS entry point.
- [x] Add RK3566 early UART support.
- [x] Establish AArch64 bootstrap CI.
- [x] Establish the repository-owned Make build.

### Physical Bring-up

- [ ] Establish the exact Stage 0 load address and handoff state.
- [ ] Link the first FeROS ELF.
- [ ] Produce the first raw Stage 0 binary.
- [ ] Construct the minimum RK3566-compatible boot image.
- [ ] Boot from the dedicated development microSD.
- [ ] Confirm execution of FeROS-owned code.
- [ ] Produce observable UART output.

### Kernel Foundation

- [ ] Exception handling.
- [ ] Interrupt controller.
- [ ] Timer.
- [ ] Physical memory management.
- [ ] MMU and virtual memory.
- [ ] Allocator.
- [ ] Scheduler and synchronization.
- [ ] Kernel logging.

### Platform Enablement

- [ ] SD/MMC.
- [ ] Input.
- [ ] Display.
- [ ] Audio.
- [ ] USB.
- [ ] Power and battery management.
- [ ] Connectivity.

### Runtime and Hardware

- [ ] Filesystem.
- [ ] Application/executable model.
- [ ] FeROS system APIs and SDK.
- [ ] Graphics, audio, and input APIs.
- [ ] Gaming runtime and native frontend.
- [ ] Additional reference hardware.
- [ ] Purpose-built FeROS hardware.

---

## Releases

- **v0.1.0** — 2026-09-20 — Bare-metal foundation.
- **v0.0.1 — Unborn** — 2026-09-20 — Historical FerroOS simulation.

See [`CHANGELOG.md`](CHANGELOG.md) for release history.

---

## Engineering Rule

No hardware address, register value, memory location, boot offset, clock
frequency, pin assignment, or electrical assumption should enter FeROS merely
because it worked somewhere else.

Hardware-specific values must be supported by architecture or SoC
documentation, target-board evidence, a trusted reference implementation, or
direct measurement.

---

## Author

Maintained by **@ialopezg**.

Ideas, experiments, technical review, and contributions are welcome.

---

## License

FeROS is licensed under the [Apache License 2.0](LICENSE).
