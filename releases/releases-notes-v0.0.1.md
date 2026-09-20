# FeROS v0.0.1 — Unborn

**Codename:** Unborn

FeROS v0.0.1 marks the first historical milestone of the project.

The project began as **FerroOS**, an experimental environment built around
Linux and Docker to explore the foundations of a retro-oriented operating
system. During this first stage, the project established its initial structure,
documentation, simulated boot behavior, frontend experiments, and automated
build validation.

As the project evolved, its direction changed fundamentally. Rather than
building a system around an existing operating-system foundation, FeROS began
moving toward a bare-metal architecture with direct ownership of the software
stack.

## Highlights

- Established the original FerroOS project and development environment.
- Created the first simulated boot and frontend experiments.
- Established the initial documentation and continuous-integration workflow.
- Transitioned the project identity from FerroOS to **FeROS**.
- Defined FeROS as a from-scratch bare-metal operating-system project.
- Established separation between architecture, SoC, and board-specific code.
- Selected the **PowKiddy X55 / Rockchip RK3566** as the first physical
  bring-up platform.
- Preserved and investigated the original X55 boot environment.
- Added the first FeROS AArch64 entry code.
- Added the first RK3566 early serial-output primitive.
- Replaced the original Docker build validation with AArch64 bootstrap
  validation.

## State of the Project

At v0.0.1, FeROS had established its identity, engineering direction, first
hardware target, initial low-level code, and the research foundation required
to continue toward physical execution.

It was not yet a bootable operating system.

There was no FeROS kernel runtime, scheduler, memory subsystem, filesystem,
graphics environment, application runtime, or complete hardware abstraction.

The project had reached the point where experimentation had become
architecture, and architecture had begun producing real machine code.

That state gives this release its codename:

## Unborn

FeROS existed in design and in its first instructions, but it had not yet
come alive on its target hardware.

---

**FeROS v0.0.1 — Unborn**

*The beginning before the first boot.*