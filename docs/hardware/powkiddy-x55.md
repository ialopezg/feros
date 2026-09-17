# PowKiddy X55 Hardware Reference

This document describes the **PowKiddy X55** as the first physical
target for **FerroOS**.

The goal is not to treat the X55 as a Linux handheld, but as an embedded
ARM64 platform on which FerroOS can eventually boot and operate
independently.

FerroOS is intended to own the complete software stack, from early boot
through hardware abstraction, kernel services, drivers, graphics, input,
audio, storage, and the final user interface.

------------------------------------------------------------------------

## FerroOS Context

FerroOS started as an experiment around retro-gaming operating systems
and embedded platforms.

The original project direction used Linux, Docker, Buildroot, RetroArch,
and existing boot infrastructure as a development path.

The project is now being reconsidered with a much more ambitious goal:

> Build an independent operating system rather than a Linux
> distribution.

The current working interpretation of the name is:

-   **Fer** --- inspired by ferrite / ferrum, representing hardware,
    core material, and low-level systems.
-   **ro** --- retro.
-   **OS** --- Operating System.

The exact original naming decision is no longer certain, but this
interpretation reflects the current identity of the project well.

### Vision

> A superb, performance-focused retro gaming operating system intended
> for fully customizable handheld consoles and embedded platforms.

FerroOS should ultimately control its own:

-   Boot process
-   Kernel
-   Memory management
-   Task scheduling
-   Hardware abstraction
-   Device drivers
-   Input subsystem
-   Graphics stack
-   Audio stack
-   Storage layer
-   Filesystems
-   Runtime environment
-   Gaming frontend

Linux may be studied, used as a hardware reference, or used temporarily
as a diagnostic environment, but it is not intended to become the
FerroOS runtime.

------------------------------------------------------------------------

# PowKiddy X55

## Device Class

The PowKiddy X55 is an ARM-based handheld gaming device.

For FerroOS, it should be viewed less as a gaming console and more as a
compact embedded computer containing:

-   ARM64 CPU cores
-   GPU
-   RAM
-   Display controller
-   LCD panel
-   Audio hardware
-   Storage controllers
-   USB
-   Wi-Fi
-   Bluetooth
-   Battery management
-   GPIO
-   Physical controls

This makes it a useful first real-world target for operating-system
development.

------------------------------------------------------------------------

## Main Hardware

### SoC

**Rockchip RK3566**

The RK3566 is a System-on-Chip rather than merely a CPU.

It integrates multiple subsystems required by an embedded computer.

### CPU

-   Architecture: ARMv8-A
-   ISA: AArch64 / ARM64
-   Cores: 4
-   Core type: ARM Cortex-A55
-   Maximum clock: approximately 1.8 GHz

Conceptually:

``` text
RK3566
├── Cortex-A55 CPU cores
├── GPU
├── Memory controller
├── Display subsystem
├── SD / eMMC controllers
├── USB
├── UART
├── SPI
├── I²C
├── GPIO
├── Audio interfaces
└── Other peripherals
```

The CPU and SoC must not be considered equivalent concepts.

The Cortex-A55 cores execute instructions.

The RK3566 SoC contains the CPU cores plus most of the surrounding
hardware required to build the system.

------------------------------------------------------------------------

## GPU

-   ARM Mali-G52 family

For FerroOS this is a later-stage target.

Initial system bring-up should not depend on GPU acceleration.

The earliest graphical output can instead use:

-   framebuffer access
-   display controller programming
-   simple software rendering

GPU initialization and acceleration can be implemented after the basic
system is operational.

------------------------------------------------------------------------

## Memory

Typical X55 configurations provide approximately:

-   2 GB LPDDR4X RAM

Hardware revisions may differ.

The exact installed memory and initialization requirements should
eventually be verified directly on the target device.

Memory is one of the first major responsibilities of FerroOS.

The system will eventually need to manage:

``` text
physical memory
       ↓
memory allocator
       ↓
virtual memory
       ↓
address spaces
       ↓
process / task memory
```

------------------------------------------------------------------------

## Display

Typical characteristics:

-   5.5-inch LCD
-   1280 × 720 resolution
-   IPS panel

The display subsystem should be considered as several distinct
components:

``` text
application / UI
        ↓
renderer
        ↓
framebuffer
        ↓
display controller
        ↓
display interface
        ↓
LCD panel
```

The LCD panel itself does not understand FerroOS.

The operating system must correctly initialize the SoC display hardware
and communicate with the physical panel.

------------------------------------------------------------------------

## Input Devices

The X55 contains integrated controls such as:

-   D-pad
-   Analog sticks
-   A / B / X / Y buttons
-   Shoulder buttons
-   Triggers
-   Start / Select-style buttons
-   Function buttons
-   Power controls
-   Volume controls

These controls are ultimately electrical inputs.

At the OS level they may be exposed through:

-   GPIO
-   ADC
-   I²C devices
-   dedicated controllers
-   other SoC peripherals

FerroOS should eventually convert those hardware events into a common
internal input model.

``` text
hardware button
      ↓
driver
      ↓
input event
      ↓
FerroOS input subsystem
      ↓
game / UI
```

------------------------------------------------------------------------

## Storage

The X55 uses microSD storage and may have additional onboard storage
depending on hardware revision.

For development, a dedicated microSD card should be treated as
disposable laboratory media.

``` text
microSD
├── boot area
├── FerroOS image
├── system data
└── game / user storage
```

During early development it may not be necessary to use conventional
partitions or filesystems at all.

The first FerroOS images may simply occupy known raw sectors on the
card.

------------------------------------------------------------------------

## Development microSD

Current laboratory card:

-   Kingston Canvas Go! Plus
-   Capacity: 256 GB
-   microSDXC
-   U3
-   V30
-   A2

This card can be safely used for:

-   raw disk images
-   experimental partition layouts
-   bootloader experiments
-   kernel images
-   filesystem experiments
-   destructive development testing

The original PowKiddy system card should remain untouched as a recovery
and hardware-reference environment.

------------------------------------------------------------------------

# Boot Architecture

A critical concept for FerroOS is that the CPU does not immediately
execute the operating system when the Power button is pressed.

There is a chain of execution.

A generalized embedded boot process looks like:

``` text
Power On
   ↓
SoC Boot ROM
   ↓
Early loader
   ↓
Bootloader
   ↓
Operating System
```

For the RK3566, the first code executed comes from immutable code
contained inside the SoC.

This is normally called the **Boot ROM**.

Its job is to find and load the next executable stage.

FerroOS therefore does not completely own the machine from the first CPU
instruction.

There is always some vendor silicon initialization before FerroOS begins
executing.

------------------------------------------------------------------------

# What Is Generic and What Is Device-Specific?

A major FerroOS design principle should be separating generic
operating-system functionality from platform-specific implementation.

The PowKiddy X55 is only one target.

FerroOS should eventually support other handhelds and embedded systems
without rewriting the complete OS.

A useful architecture is:

``` text
                 FerroOS

        ┌─────────────────────┐
        │ Applications / UI   │
        ├─────────────────────┤
        │ System services     │
        ├─────────────────────┤
        │ Kernel              │
        ├─────────────────────┤
        │ HAL                 │
        ├─────────────────────┤
        │ Platform support    │
        └─────────────────────┘
                  ↓
              Hardware
```

## Generic Components

These concepts are portable across many devices:

-   scheduler
-   task abstraction
-   synchronization primitives
-   memory allocator
-   virtual memory subsystem
-   filesystem interfaces
-   process model
-   IPC
-   event system
-   graphics API
-   audio API
-   input API
-   logging
-   system calls
-   executable loading

These should ideally know nothing about the PowKiddy X55.

For example:

``` text
kernel/input/
kernel/memory/
kernel/scheduler/
kernel/fs/
kernel/ipc/
```

## Architecture-Specific Components

Some functionality depends on the processor architecture.

For example:

``` text
arch/aarch64/
```

This layer may contain:

-   exception handling
-   interrupt entry
-   MMU setup
-   page-table management
-   CPU context switching
-   cache control
-   timers
-   boot assembly
-   atomic operations

These components could potentially work across many ARM64 devices.

They are not specific to the X55.

## SoC-Specific Components

The RK3566 requires another layer.

For example:

``` text
soc/rockchip/rk3566/
```

This may eventually contain support for:

-   interrupt controller configuration
-   clocks
-   timers
-   UART
-   GPIO
-   SD/MMC controllers
-   USB
-   display controller
-   power domains
-   reset controller
-   pin control

Another RK3566 device could reuse much of this code.

## Board-Specific Components

Finally there is the physical device.

For example:

``` text
boards/powkiddy/x55/
```

This layer defines how the RK3566 peripherals are physically connected
inside the X55.

Examples:

-   which GPIO controls a button
-   which display panel is connected
-   display timing
-   audio wiring
-   power button behavior
-   SD-card wiring
-   regulator configuration
-   Wi-Fi hardware
-   battery circuitry

This information is specific to the board.

------------------------------------------------------------------------

# Recommended FerroOS Hardware Model

A useful long-term structure could therefore be:

``` text
ferroos/
├── arch/
│   └── aarch64/
│
├── kernel/
│   ├── memory/
│   ├── scheduler/
│   ├── interrupt/
│   ├── ipc/
│   ├── input/
│   ├── graphics/
│   ├── audio/
│   └── fs/
│
├── drivers/
│   ├── block/
│   ├── display/
│   ├── input/
│   ├── audio/
│   ├── network/
│   └── usb/
│
├── soc/
│   └── rockchip/
│       └── rk3566/
│
├── boards/
│   └── powkiddy/
│       └── x55/
│
├── runtime/
│
├── user/
│
└── tools/
```

This separation is important.

The goal should be:

``` text
FerroOS
   +
architecture
   +
SoC
   +
board
```

rather than:

``` text
FerroOS == PowKiddy X55 firmware
```

------------------------------------------------------------------------

# Concepts to Remember

## CPU Architecture

``` text
ARMv8-A / AArch64
```

Defines the instruction architecture understood by the CPU.

## CPU Core

``` text
Cortex-A55
```

An ARM CPU-core implementation.

## SoC

``` text
Rockchip RK3566
```

Contains CPU cores plus numerous integrated controllers and peripherals.

## Board / Device

``` text
PowKiddy X55
```

Defines how the SoC, RAM, display, controls, storage, battery, and other
hardware are physically connected.

## Operating System

``` text
FerroOS
```

Software responsible for controlling the machine and providing execution
services to applications.

------------------------------------------------------------------------

# FerroOS Target Abstraction

A useful mental model is:

``` text
                         GENERIC

                       Application
                           │
                           ▼
                       FerroOS API
                           │
                           ▼
                         Kernel
                           │
                           ▼
                           HAL

                      ──────────────

                    HARDWARE-SPECIFIC

                           │
                           ▼
                        AArch64
                           │
                           ▼
                         RK3566
                           │
                           ▼
                     PowKiddy X55
```

As the project moves downward in this diagram, code becomes increasingly
hardware-specific.

As it moves upward, code should become increasingly portable.

------------------------------------------------------------------------

# Initial Development Strategy

The PowKiddy X55 can initially boot its existing Linux environment for
one important purpose:

**hardware reconnaissance**

Linux can reveal information about:

-   memory map
-   device tree
-   interrupt assignments
-   GPIO
-   clocks
-   input devices
-   display hardware
-   storage
-   Wi-Fi
-   Bluetooth
-   audio
-   kernel drivers

This does not mean FerroOS depends on Linux.

Linux becomes a reference implementation and diagnostic instrument.

The knowledge discovered there can later be independently implemented
inside FerroOS.

The development progression may therefore be:

``` text
Existing Linux
     ↓
Hardware reconnaissance
     ↓
Documentation
     ↓
Bare-metal experiment
     ↓
FerroOS boot code
     ↓
UART output
     ↓
Memory management
     ↓
Interrupts / timers
     ↓
Storage
     ↓
Input
     ↓
Display
     ↓
Audio
     ↓
Filesystem
     ↓
Runtime
     ↓
Gaming environment
```

------------------------------------------------------------------------

# First FerroOS Milestone

The first milestone should intentionally be extremely small.

Something comparable to:

``` text
Power On
   ↓
Boot ROM
   ↓
FerroOS entry point
   ↓
initialize stack
   ↓
initialize UART
   ↓
print:

FerroOS
Hello from RK3566
```

No Linux.

No Buildroot.

No RetroArch.

No graphical interface.

No filesystem.

Just our code executing directly on the machine.

Once this works, FerroOS exists in the literal sense.

Everything after that becomes incremental engineering.
