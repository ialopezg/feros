# FeROS - Ferrite Retro Operating System
#
# Bare-metal AArch64 bootstrap build.

CROSS_COMPILE ?= aarch64-elf-

CC      := $(CROSS_COMPILE)gcc
LD      := $(CROSS_COMPILE)ld
OBJCOPY := $(CROSS_COMPILE)objcopy
OBJDUMP := $(CROSS_COMPILE)objdump

LINKER_SCRIPT := arch/aarch64/boot/linker.ld

BUILD_DIR := build

FEROS_ELF := $(BUILD_DIR)/feros.elf
FEROS_BIN := $(BUILD_DIR)/feros.bin

ASFLAGS := \
	-ffreestanding \
	-nostdlib \
	-nostartfiles

OBJECTS := \
	$(BUILD_DIR)/arch/aarch64/boot/start.o \
	$(BUILD_DIR)/soc/rockchip/rk3566/uart.o

# Terminal styling.
RESET  := \033[0m
FERRUM := \033[1;38;5;166m
RETRO  := \033[1;38;5;214m
NATURE := \033[1;38;5;70m

# Fe = Ferrum, R = Retro, OS = Operating System.
FEROS := $(FERRUM)Fe$(RETRO)R$(NATURE)OS$(RESET)

.PHONY: all clean inspect

all: $(FEROS_ELF) $(FEROS_BIN)
	@printf "$(FEROS): AArch64 bootstrap build complete.\n"

$(BUILD_DIR)/arch/aarch64/boot/start.o: arch/aarch64/boot/start.S
	@printf "$(FEROS): assembling AArch64 entry point...\n"
	@mkdir -p $(dir $@)
	@$(CC) $(ASFLAGS) -c $< -o $@
	@printf "$(FEROS): generated %s\n" "$@"

$(BUILD_DIR)/soc/rockchip/rk3566/uart.o: soc/rockchip/rk3566/uart.S
	@printf "$(FEROS): assembling RK3566 early UART...\n"
	@mkdir -p $(dir $@)
	@$(CC) $(ASFLAGS) -c $< -o $@
	@printf "$(FEROS): generated %s\n" "$@"

$(FEROS_ELF): $(OBJECTS) $(LINKER_SCRIPT)
	@printf "$(FEROS): linking Stage 0...\n"
	@$(LD) -T $(LINKER_SCRIPT) -o $@ $(OBJECTS)
	@printf "$(FEROS): generated %s\n" "$@"

$(FEROS_BIN): $(FEROS_ELF)
	@printf "$(FEROS): generating Stage 0 binary...\n"
	@$(OBJCOPY) -O binary $< $@
	@printf "$(FEROS): generated %s\n" "$@"

inspect: all
	@printf "$(FEROS): inspecting AArch64 entry point...\n\n"
	@$(OBJDUMP) -d $(BUILD_DIR)/arch/aarch64/boot/start.o
	@printf "\n$(FEROS): inspecting RK3566 early UART...\n\n"
	@$(OBJDUMP) -d $(BUILD_DIR)/soc/rockchip/rk3566/uart.o

clean:
	@printf "$(FEROS): cleaning build artifacts...\n"
	@rm -rf $(BUILD_DIR)
	@printf "$(FEROS): clean complete.\n"