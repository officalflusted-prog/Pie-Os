# Pi OS Kernel Makefile
BUILD_VERSION = 0.9.2a
NASM    = nasm
LD      = ld
QEMU32  = qemu-system-i386
QEMU64  = qemu-system-x86_64
IMAGE   = piOS.img
KERNEL  = kernel.bin
BOOT    = boot.bin
MEM_SIZE= 128

# Linker scripts
LDSCRIPT32 = linker.ld
LDSCRIPT64 = linker64.ld

# Build mode switch
ifeq ($(BUILD64),1)
  NASM_FMT = elf64
  LD_ARCH  = elf_x86_64
  LDSCRIPT = $(LDSCRIPT64)
  QEMU     = $(QEMU64)
else
  NASM_FMT = elf32
  LD_ARCH  = elf_i386
  LDSCRIPT = $(LDSCRIPT32)
  QEMU     = $(QEMU32)
endif

# Source list (all .asm)
SRCS = \
 achi_driver.asm app_env.asm assembly_loader.asm boot.asm boot_config.asm \
 clr_host.asm deflate.asm deflate.asm1 desktop_manager.asm devfs.asm device_driver.asm \
 disk_cache.asm disk_io.asm drive_manager.asm ext2_driver.asm fat12.asm fl_api.asm \
 font_renderer gdt_idt.asm graphics.asm guest_loader.asm i18n.asm input.asm \
 interrupts.asm journal.asm kbd_layout.asm kernel.asm lib.asm linker.ld lmode_switch.asm \
 metrics.asm nic_driver.asm nic_isr.asm pager.asm pci.asm pe_loader.asm pipe.asm \
 pmode_switch.asm qemu_config.inc registry.asm render_api.asm security.asm shell.asm \
 shell_scripts.asm start_menu.asm syscall.asm syscall_translator.asm task_manager.asm \
 taskbar.asm tcpip.asm timer_sched.asm unicode.asm vnc_protocol.asm xstartup.asm

# Objects: map .asm -> .o (skip non-asm files)
OBJS = $(patsubst %.asm,%.o,$(filter %.asm,$(SRCS)))

.PHONY: all clean run kernel image

all: $(IMAGE)
	@echo "=========================================="
	@echo "  PI OS BUILD SUCCESSFUL"
	@echo "  Version: $(BUILD_VERSION)"
	@echo "  Mode: $(if $(BUILD64),64-bit,32-bit)"
	@echo "=========================================="

# Assemble boot to raw 512B sector (bin)
$(BOOT): boot.asm
	$(NASM) -f bin $< -o $@

# Assemble all .asm sources to objects
%.o: %.asm
	$(NASM) -f $(NASM_FMT) $< -o $@

# Link kernel objects to a flat binary with the selected linker script
$(KERNEL): $(OBJS) $(LDSCRIPT)
	$(LD) -m $(LD_ARCH) -T $(LDSCRIPT) -o $@ $(OBJS)

# Stitch boot + kernel into raw image
$(IMAGE): $(BOOT) $(KERNEL)
	cat $(BOOT) $(KERNEL) > $(IMAGE)
	@echo "-> Image assembled: $(IMAGE)"

run: $(IMAGE)
	$(QEMU) -drive format=raw,file=$(IMAGE) -m $(MEM_SIZE) -vnc :1 -name "Pi OS v$(BUILD_VERSION)"

clean:
	rm -f $(OBJS) $(KERNEL) $(IMAGE) $(BOOT)
