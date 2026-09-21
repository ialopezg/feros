# FeROS

**Ferrite Retro Operating System**

[![License: Apache
2.0](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Build](https://img.shields.io/github/actions/workflow/status/ialopezg/feros/ci.yml?branch=main)](https://github.com/ialopezg/feros/actions)
[![Architecture](https://img.shields.io/badge/architecture-AArch64-brightgreen)](docs/engineering-architecture.md)
[![Target](https://img.shields.io/badge/bring--up-PowKiddy%20X55-orange)](docs/hardware/powkiddy-x55.md)
[![QEMU](https://img.shields.io/badge/platform-QEMU%20ARM64%20-blueviolet.svg)](boards/qemu/virt)

**FeROS** is a performance-first independent operating system being
built from scratch for retro handhelds and embedded gaming hardware.

The PowKiddy X55 is the first physical development platform. It is a
hardware laboratory for FeROS, not the permanent definition of the
operating system.

> **Close to the metal.**
>
> **No magic. Every layer is visible.**

------------------------------------------------------------------------

## Project Identity

The name **FeROS** expresses the project's three core ideas:

-   **Fe** --- Ferrite, with an additional association to iron (`Fe`),
    hardware, physicality, and low-level engineering.
-   **R** --- Retro.
-   **OS** --- Operating System.

FeROS began as **FerroOS**, a Linux/Docker-based experiment. That
original simulation is preserved as `v0.0.1 — Unborn`.

With `v0.1.0`, the project transitioned into an independent bare-metal
operating-system effort.

------------------------------------------------------------------------

## Project Philosophy

-   Hardware-first.
-   Predictable behavior over unnecessary abstraction.
-   Minimal magic; important layers should remain observable.
-   Performance and debuggability are design concerns from the
    beginning.
-   Generic kernel code must remain independent of individual handheld
    models.
-   Architecture-, SoC-, and board-specific responsibilities must remain
    separated.
-   Hardware constants must be traceable to evidence.
-   Documentation is part of the engineering product.
-   Linux may be used for hardware reconnaissance, but it is not the
    FeROS runtime.

------------------------------------------------------------------------

## Architecture

FeROS separates portable operating-system code from architecture, SoC,
and board-specific implementation:

``` text
Application / Game
       |
   FeROS API
       |
     Kernel
       |
    Drivers
       |
--------------- hardware boundary ---------------
       |
    AArch64
       |
 Rockchip RK3566
       |
 PowKiddy X55
```

> We learn from the X55. We port FeROS to the X55. We do not design
> FeROS around the X55.

Current source boundaries:

``` text
feros/
├── arch/
│   └── aarch64/
│       └── boot/
├── soc/
│   ├── rockchip/
│   │   └── rk3566/
│   │       └── firmware/
│   └── allwinner/
│       └── a133p/
├── boards/
│   ├── powkiddy/
│   │   └── x55/
│   ├── qemu/
│   │   └── virt/
│   └── trimui/
│       └── smart-pro/
├── kernel/
├── drivers/
├── runtime/
├── sdk/
├── tools/
│   └── image/
│       └── rk3566/
├── docs/
├── research/
├── Makefile
├── LICENSE
└── README.md
```

The TrimUI Smart Pro / Allwinner A133P paths reserve architectural
boundaries for future investigation. They do not represent implemented
hardware support.

------------------------------------------------------------------------

## Platforms

FeROS currently has two active development platforms:

-   **PowKiddy X55 / Rockchip RK3566** --- first physical hardware
    bring-up target.
-   **QEMU ARM64 `virt`** --- virtual development platform for executing
    and validating FeROS Stage 0 independently of the physical X55
    bring-up path.

The QEMU platform provides its own board implementation and PL011 early
UART while sharing the generic AArch64 bootstrap contract. It is a
development platform, not an emulation of the RK3566 or PowKiddy X55.

The TrimUI Smart Pro / Allwinner A133P remains reserved for future
hardware investigation and is not yet an active FeROS platform.

------------------------------------------------------------------------

## Current Bring-up State

The active hardware target is:

``` text
Architecture : AArch64 / ARMv8-A
SoC          : Rockchip RK3566
Board        : PowKiddy X55
```

Investigation of the original X55 boot media established the early boot
model:

``` text
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
FeROS Stage 0
```

FeROS contains its first AArch64 entry point and platform-independent
early UART contract, with implementations for the RK3566 and QEMU ARM64
`virt` platform.

FeROS Stage 0 is linked as an ELF and raw binary for both supported
build targets. The QEMU target executes FeROS-owned AArch64 code and
produces observable UART output.

For the RK3566, FeROS now generates a clean RKNS boot image from
explicit inputs rather than copying the original X55 boot area. The
image contains the required RKNS metadata, the current DDR
initialization payload, and FeROS Stage 0, with SHA-256 validation of
the header and payloads.

The immediate physical milestone remains observable execution of
FeROS-owned code on the PowKiddy X55.

------------------------------------------------------------------------

## Engineering Console

The repository provides a small engineering console through GNU Make:

``` bash
make
```

``` text
FeROS — Engineering Console

  1) Build
  2) Inspect artifacts
  3) Validate artifacts
  4) Prepare boot image
  5) Prepare target media
  6) Run
  7) Help
  8) Quit
```

The workflow deliberately separates compilation, inspection, validation,
platform boot-image packaging, physical-media preparation, and
execution.

Common non-interactive targets include:

``` bash
make all
make x55
make qemu

make inspect-all
make validate-all

make prepare-x55
make run
```

Detailed development-environment setup, toolchain installation,
commands, and troubleshooting are documented in the [FeROS Installation
Guide](docs/installation.md).

------------------------------------------------------------------------

## Boot Image Tooling

Platform boot formats are kept outside the generic FeROS build
architecture.

The current Rockchip RK3566 tooling builds and validates the RKNS image
used for X55 bring-up:

``` text
tools/image/rk3566/
├── mkimage.py
└── README.md
```

The current generated X55 image is:

``` text
build/x55/boot/feros-x55.img
```

Its high-level layout is:

``` text
0x00000  Reserved / zero-filled boot area
0x08000  RKNS header
0x08800  DDR initialization payload
...      FeROS Stage 0 at the next sector after DDR
```

The Stage 0 offset is calculated from the DDR payload size and is not a
universal FeROS architectural constant.

See the [RK3566 Boot Image Tool](tools/image/rk3566/README.md) for the
RKNS format, descriptors, hashing, image construction, and validation
details.

------------------------------------------------------------------------

## Implementation Direction

The initial implementation uses:

-   **C** for kernel, platform, runtime, and driver code as those layers
    emerge.
-   **AArch64 assembly** where direct architectural control is required.

Early FeROS is freestanding. It cannot assume libc, `printf`, `malloc`,
processes, files, or another operating system.

------------------------------------------------------------------------

## Documentation

The README intentionally remains an executive overview. Detailed setup,
architecture, hardware evidence, and platform bring-up information live
in focused engineering documents.

Current references include:

-   [`docs/installation.md`](docs/installation.md)
-   [`docs/architecture/current-layout.md`](docs/architecture/current-layout.md)
-   [`docs/platforms/powkiddy-x55-bringup.md`](docs/platforms/powkiddy-x55-bringup.md)
-   [`docs/hardware/powkiddy-x55.md`](docs/hardware/powkiddy-x55.md)
-   [`docs/hardware/rk3566-boot.md`](docs/hardware/rk3566-boot.md)
-   [`docs/engineering-architecture.md`](docs/engineering-architecture.md)
-   [`docs/developer-guide.md`](docs/developer-guide.md)
-   [`tools/image/rk3566/README.md`](tools/image/rk3566/README.md)

Documentation should record not only what works, but why a design exists
and which hardware evidence supports it.

------------------------------------------------------------------------

## Development Roadmap

### Foundation

-   [x] Preserve the original FerroOS history.
-   [x] Establish FeROS as a bare-metal operating-system project.
-   [x] Establish architecture, SoC, and board boundaries.
-   [x] Establish the PowKiddy X55 / RK3566 as the first bring-up
    platform.
-   [x] Preserve the original X55 boot-area captures.
-   [x] Identify and validate the RKNS/new-IDB structure.
-   [x] Identify the DDR initialization and SPL payload boundaries.
-   [x] Add the first AArch64 FeROS entry point.
-   [x] Add RK3566 early UART support.
-   [x] Establish AArch64 bootstrap CI.
-   [x] Establish the repository-owned Make build.
-   [x] Add QEMU ARM64 `virt` as a development platform.
-   [x] Execute FeROS Stage 0 under QEMU with observable UART output.
-   [x] Add RK3566 RKNS image construction and validation tooling.

### Physical Bring-up

-   [ ] Establish the exact Stage 0 load address and handoff state.
-   [x] Link the first FeROS ELF.
-   [x] Produce the first raw Stage 0 binary.
-   [x] Construct and validate the minimum RK3566-compatible boot image.
-   [ ] Prepare the dedicated development microSD through FeROS tooling.
-   [ ] Boot from the dedicated development microSD.
-   [ ] Confirm execution of FeROS-owned code.
-   [ ] Produce observable UART output.

### Kernel Foundation

-   [ ] Exception handling.
-   [ ] Interrupt controller.
-   [ ] Timer.
-   [ ] Physical memory management.
-   [ ] MMU and virtual memory.
-   [ ] Allocator.
-   [ ] Scheduler and synchronization.
-   [ ] Kernel logging.

### Platform Enablement

-   [ ] SD/MMC.
-   [ ] Input.
-   [ ] Display.
-   [ ] Audio.
-   [ ] USB.
-   [ ] Power and battery management.
-   [ ] Connectivity.

### Runtime and Hardware

-   [ ] Filesystem.
-   [ ] Application/executable model.
-   [ ] FeROS system APIs and SDK.
-   [ ] Graphics, audio, and input APIs.
-   [ ] Gaming runtime and native frontend.
-   [ ] Additional reference hardware.
-   [ ] Purpose-built FeROS hardware.

------------------------------------------------------------------------

## Releases

-   **v0.1.1** --- 2026-09-20 --- QEMU platform and multi-platform
    workflow.
-   **v0.1.0** --- 2026-09-20 --- Bare-metal foundation.
-   **v0.0.1 --- Unborn** --- 2026-09-20 --- Historical FerroOS
    simulation.

See [`CHANGELOG.md`](CHANGELOG.md) for release history.

------------------------------------------------------------------------

## Engineering Rule

No hardware address, register value, memory location, boot offset, clock
frequency, pin assignment, or electrical assumption should enter FeROS
merely because it worked somewhere else.

Hardware-specific values must be supported by architecture or SoC
documentation, target-board evidence, a trusted reference
implementation, or direct measurement.

------------------------------------------------------------------------

## Author

Maintained by **@ialopezg**.

Ideas, experiments, technical review, and contributions are welcome.

------------------------------------------------------------------------

## License

FeROS is licensed under the [Apache License 2.0](LICENSE).
