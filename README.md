# FeROS

**Ferrite Retro Operating System**

[![License: Apache 2.0](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Build](https://img.shields.io/github/actions/workflow/status/ialopezg/ferroos/ci.yml?branch=main)](https://github.com/ialopezg/ferroos/actions)
[![Architecture](https://img.shields.io/badge/architecture-AArch64-brightgreen)](docs/engineering-architecture.md)
[![Target](https://img.shields.io/badge/bring--up-PowKiddy%20X55%20%7C%20RK3566-orange)](docs/hardware/powkiddy-x55.md)

**FeROS** is a performance-first independent operating system being built from
scratch for retro handhelds and embedded gaming hardware.

The PowKiddy X55 is the first physical development platform. It is a hardware
laboratory for FeROS, not the permanent definition of the operating system.
The long-term direction includes custom handhelds, custom PCBs, enclosures,
controls, and future hardware designed specifically for FeROS.

> **Close to the metal.**

---

## Project Identity

The name **FeROS** expresses the project's three core ideas:

- **Fe** — Ferrite, with an additional association to iron (`Fe`), hardware,
  physicality, and low-level engineering.
- **R** — Retro.
- **OS** — Operating System.

FeROS originally began as **FerroOS**, a Linux/Docker/Buildroot-oriented
experiment. That implementation is now historical context. The current project
is an independent operating-system effort rather than a Linux distribution.

---

## Project Philosophy

- Hardware-first.
- Predictable behavior over unnecessary abstraction.
- Minimal magic; important layers should remain observable.
- Performance and debuggability are design concerns from the beginning.
- Generic kernel code must remain independent of individual handheld models.
- Architecture-, SoC-, and board-specific responsibilities must remain
  separated.
- Hardware constants must be traceable to documentation, trusted reference
  implementations, board evidence, or direct measurement.
- Documentation is part of the engineering product.
- Linux may be used for hardware reconnaissance, but it is not the FeROS
  runtime.

FeROS intends to progressively own the software stack after the unavoidable
silicon/vendor bootstrap boundary:

```text
Boot ROM / required SoC bootstrap
              |
              v
        FeROS early boot
              |
              v
          FeROS kernel
              |
              v
        HAL and drivers
              |
              v
      runtime / system APIs
              |
              v
      applications / games
```

During initial RK3566 bring-up, FeROS may temporarily retain the minimum vendor
bootstrap required for tasks such as DRAM initialization. Such components are
bootstrap dependencies, not part of the FeROS kernel.

---

## First Hardware Target

The first target is the **PowKiddy X55**, based on the **Rockchip RK3566**.

```text
Architecture
└── AArch64 / ARMv8-A
    └── SoC
        └── Rockchip RK3566
            └── Development board
                └── PowKiddy X55
```

This separation is deliberate. FeROS should eventually be able to support
other boards using the same SoC, other AArch64 SoCs, and potentially additional
architectures without turning the generic kernel into device-specific
firmware.

---

## Current Bring-up Goal

The first FeROS milestone is intentionally small:

```text
Power On
   |
   v
RK3566 BootROM
   |
   v
required early bootstrap / DDR initialization
   |
   v
FeROS early entry
   |
   v
establish required CPU state / stack
   |
   v
initialize verified debug UART
   |
   v
"FeROS booting..."
```

No Linux runtime. No Buildroot runtime. No RetroArch. No filesystem. No GUI.

The milestone is achieved when observable FeROS code executes on the physical
RK3566.

Before source-code constants are introduced, the RK3566 BootROM contract,
image layout, handoff state, UART controller, MMIO addresses, pinmux, physical
debug pads, and electrical levels must be verified.

---

## Source Architecture

The source tree is being rebuilt around explicit hardware boundaries:

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
├── kernel/              # Added as generic kernel requirements emerge
├── drivers/             # Added as driver abstractions emerge
├── runtime/             # Later-stage runtime
├── tools/               # Build/image/development tooling
├── LICENSE
└── README.md
```

Directories and abstractions should be introduced when they represent an
actual engineering requirement rather than populated speculatively.

### Layer responsibilities

- `arch/aarch64/` — AArch64 execution mechanics: entry, exceptions, MMU,
  context switching, cache operations, and architecture-specific primitives.
- `soc/rockchip/rk3566/` — RK3566 integrated peripherals and SoC behavior.
- `boards/powkiddy/x55/` — physical X55 wiring, components, and board-specific
  configuration.
- `kernel/` — portable operating-system mechanisms that should know nothing
  about the PowKiddy X55.

---

## Implementation Direction

The initial implementation will primarily use:

- **C** for kernel, platform, and driver code.
- **AArch64 assembly** only where required by the architecture, such as the
  earliest entry code, exception vectors, special CPU operations, and context
  switching.

Early FeROS code is freestanding. It must not assume the existence of libc,
`printf`, `malloc`, a filesystem, processes, or another operating system.

Additional languages may be evaluated later when FeROS has enough runtime
infrastructure to support them deliberately.

---

## Documentation

Current engineering references:

- [`docs/hardware/powkiddy-x55.md`](docs/hardware/powkiddy-x55.md) — X55
  hardware model and board-specific development reference.
- [`docs/hardware/rk3566-boot.md`](docs/hardware/rk3566-boot.md) — RK3566 boot
  architecture, bootstrap boundary, and bring-up investigation backlog.
- [`docs/engineering-architecture.md`](docs/engineering-architecture.md) —
  architecture documentation; being migrated from the historical FerroOS
  design to the current FeROS architecture.
- [`docs/developer-guide.md`](docs/developer-guide.md) — developer guide; being
  migrated to the bare-metal FeROS toolchain and workflow.
- `docs/FeROS_Project_Vision_Architecture_and_Brand_Identity.docx` — project
  vision, identity, architectural direction, and initial brand study.

Documentation should record not only what works, but why a design exists and
which hardware evidence supports it.

---

## Development Roadmap

### Phase 0 — Project Transition

- [x] Preserve FerroOS history in Git.
- [x] Remove the Docker/Linux simulation runtime from the active architecture.
- [x] Establish FeROS identity and project direction.
- [x] Establish AArch64 / RK3566 / X55 architectural boundaries.
- [x] Create the initial X55 hardware reference.
- [x] Create the RK3566 boot investigation document.

### Phase 1 — RK3566 Bare-Metal Bring-up

- [ ] Verify the RK3566 BootROM SD boot contract.
- [ ] Verify the required IDB/first-stage image format.
- [ ] Establish the minimum DDR/bootstrap dependency.
- [ ] Determine the FeROS execution address and CPU handoff state.
- [ ] Verify X55 debug UART hardware and electrical characteristics.
- [ ] Implement the first AArch64 FeROS entry point.
- [ ] Build and link the first freestanding FeROS image.
- [ ] Boot from the dedicated development microSD.
- [ ] Produce observable UART output from FeROS.

### Phase 2 — Kernel Foundation

- [ ] Exception handling.
- [ ] Interrupt controller support.
- [ ] System timer.
- [ ] Physical memory management.
- [ ] MMU and virtual memory.
- [ ] Basic allocator.
- [ ] Task abstraction and scheduler.
- [ ] Structured kernel logging.

### Phase 3 — X55 Hardware Enablement

- [ ] SD/MMC storage.
- [ ] Input controls.
- [ ] Display controller and framebuffer.
- [ ] Audio.
- [ ] USB.
- [ ] Battery and power management.
- [ ] Wi-Fi and Bluetooth investigation.

### Phase 4 — Runtime and Gaming Platform

- [ ] Filesystem layer.
- [ ] Executable/application model.
- [ ] FeROS system API / SDK.
- [ ] Graphics API.
- [ ] Audio API.
- [ ] Input API.
- [ ] Gaming runtime.
- [ ] Native FeROS frontend.

### Phase 5 — FeROS Hardware

- [ ] Define requirements for a custom handheld.
- [ ] Select and validate production SoC and supporting components.
- [ ] Design custom PCB.
- [ ] Prototype controls, display, audio, storage, power, and connectivity.
- [ ] Design and fabricate the enclosure.
- [ ] Create a FeROS board-support package.
- [ ] Boot FeROS on custom hardware.

---

## Engineering Rule

No hardware address, register value, memory location, boot offset, clock
frequency, or pin assignment should enter FeROS merely because it worked on
another board.

Every such value should be traceable to one or more of:

1. architecture or SoC technical documentation,
2. target-board hardware evidence,
3. a trusted reference implementation, or
4. direct measurement on the physical target.

The X55 is where we learn how to bring FeROS to life. It is not where the
architecture ends.

---

## Author

Maintained by **@ialopezg**.

Ideas, experiments, technical review, and contributions are welcome.

---

## License

FeROS is licensed under the [Apache License 2.0](LICENSE).
