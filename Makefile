# Pi OS Kernel Makefile
BUILD_VERSION = 0.9.1a
NASM    = nasm
LD      = ld
QEMU    = qemu-system-x86_64
IMAGE   = piOS.img
KERNEL  = piOS.bin
BOOT    = boot_loader.bin
LDSCRIPT= linker.ld
MEM_SIZE= 128

CORE_OBJS = kernel.o gdt_idt.o vmem.o pager.o syscall.o timer_sched.o syscall_translator.o metrics.o
DRIVER_OBJS = pci.o driver_manager.o disk_io.o ahci_driver.o input_manager.o mouse_driver.o serial_port.o usb_driver.o rtl8139_driver.o
FS_OBJS = ext2_driver.o journal.o registry.o boot_config.o devfs.o app_env.o
GUI_OBJS = fb_manager.o fl.o fl_api.o vnc_server.o window_manager.o window_server.o taskbar.o start_menu.o
TEXT_OBJS = kbd_layout.o unicode.o i18n.o font_renderer.o
APP_OBJS = task_manager.o pe_loader.o clr_host.o assembly_loader.o security.o threads.o
UTIL_OBJS = shell.o guest_loader.o net_stack.o tcp_ip.o zlib.o

OBJECTS = $(CORE_OBJS) $(DRIVER_OBJS) $(FS_OBJS) $(GUI_OBJS) $(TEXT_OBJS) $(APP_OBJS) $(UTIL_OBJS)

.PHONY: all clean run

all: $(IMAGE)
	@echo "=========================================="
	@echo "  PI OS BUILD SUCCESSFUL"
	@echo "  Version: $(BUILD_VERSION)"
	@echo "=========================================="

$(KERNEL): $(OBJECTS) $(LDSCRIPT)
	$(LD) -m elf_i386 -T $(LDSCRIPT) -o $(KERNEL) $(OBJECTS)

$(IMAGE): $(KERNEL) $(BOOT)
	cat $(BOOT) $(KERNEL) > $(IMAGE)
	@echo "-> Image size check complete."

%.o: %.asm
	$(NASM) -f elf32 $< -o $@

run: $(IMAGE)
	$(QEMU) -drive format=raw,file=$(IMAGE) -m $(MEM_SIZE) -vnc :1 -name "Pi OS Kernel v$(BUILD_VERSION)"

clean:
	rm -f $(OBJECTS) $(KERNEL) $(IMAGE)
