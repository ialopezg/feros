# FeROS v0.1.0

**Release date:** 2026-09-20

## ✨ Highlights

* Transitioned FeROS from the original simulated environment to a bare-metal operating-system project.
* Established explicit architecture, SoC, board, kernel, driver, runtime, SDK, and tooling boundaries.
* Established the PowKiddy X55 / Rockchip RK3566 as the first hardware bring-up platform.
* Preserved and investigated the original X55 boot environment and RKNS/new-IDB structure.
* Added the first freestanding AArch64 entry point and RK3566 early UART support.
* Established the AArch64 bootstrap build, CI validation, and repository-owned Make build.

## 🧱 Architecture

FeROS now separates portable operating-system code from architecture, SoC, and
board-specific implementation:

```text
FeROS
├── arch/aarch64
├── soc/rockchip/rk3566
├── boards/powkiddy/x55
├── kernel
├── drivers
├── runtime
├── sdk
└── tools
```

The PowKiddy X55 is the first bring-up platform, not the definition of FeROS.

## ⚙️ Bootstrap

The RK3566/X55 investigation established the initial boot boundary:

```text
RK3566 BootROM
      |
      v
RKNS / required bootstrap
      |
      v
FeROS Stage 0
```

FeROS now contains its first AArch64 entry code and an early RK3566 UART
transmit primitive.

## 🛠️ Build

The project now has an explicit AArch64 bootstrap build.

```bash
make
make inspect
make clean
```

The cross-toolchain prefix can be overridden with `CROSS_COMPILE`, allowing the
same repository-owned build definition to be used locally and by CI.

## 🚧 Current State

FeROS v0.1.0 establishes the bare-metal foundation, but does not yet claim a
complete physical boot on the PowKiddy X55.

The next milestone is execution of FeROS-owned code on the physical hardware
with an observable result.
