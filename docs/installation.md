# FeROS Installation

This guide describes how to prepare a development environment for
building, inspecting, validating, packaging, and running FeROS.

FeROS is designed as a platform-independent operating system project.
Individual hardware targets may require additional platform-specific
tooling, firmware, or boot-image preparation steps.

> **Engineering principle:** No magic. Every layer is visible.

## Requirements

A FeROS development environment currently requires:

-   Git
-   GNU Make
-   Python 3
-   An AArch64 cross-compilation toolchain
-   QEMU for virtual ARM64 execution
-   Platform-specific dependencies when preparing physical target images

The project does not require a hosted C runtime or standard C library
for the early bootstrap.

## Clone the Repository

Clone the FeROS repository and enter the project directory:

``` bash
git clone https://github.com/ialopezg/feros.git
cd feros
```

The main development interface is the FeROS Engineering Console:

``` bash
make
```

It exposes the primary workflow:

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

Direct Make targets are also available for development and automation.

## AArch64 Toolchain

FeROS requires an AArch64 cross toolchain capable of assembling and
linking freestanding ARM64 code.

The Makefile uses the `CROSS_COMPILE` prefix and defaults to:

``` text
aarch64-elf-
```

### macOS

Install an AArch64 bare-metal toolchain that provides commands such as:

``` text
aarch64-elf-gcc
aarch64-elf-ld
aarch64-elf-objcopy
aarch64-elf-objdump
```

Verify the toolchain:

``` bash
aarch64-elf-gcc --version
aarch64-elf-ld --version
```

### Linux

On Debian or Ubuntu, the GNU AArch64 Linux cross toolchain can be used
for the current bootstrap:

``` bash
sudo apt-get update
sudo apt-get install -y \
  gcc-aarch64-linux-gnu \
  binutils-aarch64-linux-gnu
```

Use it by overriding the cross-compiler prefix:

``` bash
make CROSS_COMPILE=aarch64-linux-gnu- all
```

This is also the toolchain configuration used by FeROS continuous
integration.

## Python

Python 3 is required by platform-specific image tooling.

Verify the installation:

``` bash
python3 --version
```

The current Rockchip RK3566 image builder uses only Python functionality
provided by the project tool and does not require a separate Python
application framework.

## QEMU

QEMU provides the current virtual ARM64 development platform.

Install a QEMU distribution that includes:

``` text
qemu-system-aarch64
```

Verify it:

``` bash
qemu-system-aarch64 --version
```

FeROS uses the QEMU `virt` machine with a Cortex-A55 CPU for the current
virtual bring-up environment.

## Build FeROS

### All Platforms

Build every currently supported platform:

``` bash
make all
```

### PowKiddy X55

Build the PowKiddy X55 bootstrap:

``` bash
make x55
```

The X55 is a reference platform for FeROS bring-up. FeROS is not
architected around the X55.

The current X55 target uses:

-   Rockchip RK3566
-   AArch64
-   FeROS Stage 0
-   RK3566-specific early UART support

### QEMU ARM64 virt

Build the QEMU virtual platform:

``` bash
make qemu
```

Generated artifacts are placed under the platform-specific build
directory:

``` text
build/
├── x55/
└── qemu/
```

The principal bootstrap artifacts are:

``` text
feros.elf
feros.bin
```

## Inspect Build Artifacts

Inspection examines generated artifacts without defining the platform
architecture around a particular development host.

Inspect all platforms:

``` bash
make inspect-all
```

Inspect the X55:

``` bash
make inspect-x55
```

Inspect QEMU:

``` bash
make inspect-qemu
```

Inspection includes the AArch64 entry point, platform early-UART object,
and Stage 0 ELF metadata.

Inspection is conceptually separate from building. Existing artifacts
should be built before they are inspected.

## Validate Build Artifacts

Validation verifies existing generated artifacts.

Validate all platforms:

``` bash
make validate-all
```

Validate the X55:

``` bash
make validate-x55
```

Validate QEMU:

``` bash
make validate-qemu
```

Validation does not represent a build operation. Its purpose is to
verify artifacts that already exist.

For the X55, RKNS boot-image validation is also performed when the
prepared image exists.

## Prepare a Boot Image

A generic FeROS build produces platform ELF and binary artifacts.
Physical hardware may require an additional boot-image format imposed by
its SoC boot contract.

For the PowKiddy X55:

``` bash
make prepare-x55
```

This operation:

1.  Builds the X55 Stage 0 artifacts.
2.  Packages the RK3566 boot image.
3.  Includes the current RK3566 DDR initialization payload.
4.  Generates the RKNS metadata and payload descriptors.
5.  Calculates the required SHA-256 hashes.
6.  Validates the resulting image.

The generated image is:

``` text
build/x55/boot/feros-x55.img
```

The current clean RK3566 layout begins with a zero-filled boot area and
places the RKNS structure at sector 64:

``` text
0x00000  Reserved / zero-filled boot area
0x08000  RKNS header
0x08800  DDR initialization payload
...      FeROS Stage 0 at the next sector after the DDR payload
```

The Stage 0 physical offset is calculated from the DDR payload size. It
must not be treated as a universal FeROS architectural constant.

For details about the RK3566 image format and tooling, see:

``` text
tools/image/rk3566/README.md
```

## Run FeROS

Run FeROS on the QEMU ARM64 virtual platform:

``` bash
make run
```

The current execution environment is equivalent to:

``` bash
qemu-system-aarch64 \
  -machine virt \
  -cpu cortex-a55 \
  -nographic \
  -kernel build/qemu/feros.elf
```

A successful early bootstrap currently prints:

``` text
FeROS
```

QEMU is a separate FeROS development platform. It is not an RK3566
emulator and does not reproduce the PowKiddy X55 boot process.

## Target Media

Physical target-media preparation is deliberately separated from
boot-image generation.

The Engineering Console exposes:

``` text
Prepare target media
```

For the X55, the intended target is a microSD card.

Physical-media operations are destructive by nature and must never
assume a fixed device identifier. A safe target-media workflow must
identify the candidate device, display its properties, require explicit
confirmation, write only after verification, and verify the written data
afterward.

Until those safeguards are implemented and validated, target-media
preparation must not silently write to a storage device.

## Cleaning Generated Artifacts

Remove generated build artifacts:

``` bash
make clean
```

This removes the build tree and does not modify source files, firmware
sources, research material, or physical target media.

## Continuous Integration

FeROS CI uses explicit non-interactive Make targets rather than the
Engineering Console.

The intended CI workflow is:

``` bash
make CROSS_COMPILE=aarch64-linux-gnu- all
make CROSS_COMPILE=aarch64-linux-gnu- inspect-all
make CROSS_COMPILE=aarch64-linux-gnu- validate-all
```

Interactive `make` is intended for local engineering use.

## Troubleshooting

### Cross compiler not found

Verify the selected prefix:

``` bash
which aarch64-elf-gcc
```

or, on systems using the Linux GNU cross toolchain:

``` bash
which aarch64-linux-gnu-gcc
```

Override the prefix when necessary:

``` bash
make CROSS_COMPILE=aarch64-linux-gnu- all
```

### QEMU not found

Verify:

``` bash
which qemu-system-aarch64
```

Install a QEMU package containing the ARM64 system emulator if the
command is unavailable.

### Missing build artifacts

Build the relevant platform before using inspection or validation
commands:

``` bash
make all
```

### X55 boot image validation fails

Regenerate the image:

``` bash
make prepare-x55
```

If validation still fails, inspect the RK3566 image-tool documentation
and verify that the DDR firmware dependency and Stage 0 binary are
present.

## Platform Philosophy

Commercial SoCs may contain immutable BootROM behavior that FeROS cannot
replace. FeROS treats that immutable behavior as part of the hardware
contract and takes ownership of the software stack at the earliest
practical instruction.

Reference hardware exists to teach FeROS how real machines boot.

**We learn from the hardware. We port FeROS to the hardware. We do not
design FeROS around the hardware.**

------------------------------------------------------------------------

FeROS --- Ferrite Retro Operating System

**Close to the metal.**
