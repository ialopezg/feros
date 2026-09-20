# Changelog

All notable changes to FeROS are documented in this file.

The project follows Semantic Versioning.

## [0.1.1] - 2026-09-20

### Added

- Added QEMU ARM64 `virt` as a development platform.
- Added PL011 early UART support for QEMU.
- Added verified FeROS Stage 0 execution under QEMU with observable UART output.
- Added platform-specific ELF and raw binary builds for X55 and QEMU.

### Changed

- Expanded the Make workflow with explicit X55, QEMU, and all-platform build and inspection targets.
- Added interactive platform selection, command help, and QEMU execution through `make run`.
- Updated documentation to distinguish QEMU development from physical X55 bring-up.

---

## [0.1.0] - 2026-09-20

### Added

- Added the first AArch64 FeROS entry point.
- Added RK3566 early UART support.
- Added X55 boot-area research and RKNS/new-IDB investigation.
- Added explicit architecture, SoC, board, kernel, driver, runtime, SDK, and tooling boundaries.
- Added the AArch64 bootstrap build and repository-owned Make build.

### Changed

- Transitioned the project from the historical FerroOS simulation to a bare-metal operating-system architecture.
- Replaced Docker-oriented CI with AArch64 bootstrap validation.
- Established the PowKiddy X55 / RK3566 as the first hardware bring-up platform.

---

## [0.0.1] - 2026-09-20

### Added

- Added the original FerroOS project structure and documentation.
- Added the Docker-based development environment.
- Added the initial CI workflow.
- Added the simulated boot and frontend experiment.
