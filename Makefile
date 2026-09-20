# FeROS - Ferrite Retro Operating System
#
# Bare-metal AArch64 bootstrap build.

CROSS_COMPILE ?= aarch64-elf-

CC      := $(CROSS_COMPILE)gcc
OBJDUMP := $(CROSS_COMPILE)objdump

BUILD_DIR := build

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

all: $(OBJECTS)
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

inspect: all
	@printf "$(FEROS): inspecting AArch64 entry point...\n\n"
	@$(OBJDUMP) -d $(BUILD_DIR)/arch/aarch64/boot/start.o
	@printf "\n$(FEROS): inspecting RK3566 early UART...\n\n"
	@$(OBJDUMP) -d $(BUILD_DIR)/soc/rockchip/rk3566/uart.o

clean:
	@printf "$(FEROS): cleaning build artifacts...\n"
	@rm -rf $(BUILD_DIR)
	@printf "$(FEROS): clean complete.\n"