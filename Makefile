----------------------------------------------------------------------
Pi OS Kernel Makefile
Automates the assembly, linking, and image creation for the 51-file Pi OS.
----------------------------------------------------------------------
--- Configuration & Versioning ---
BUILD_VERSION = 0.9.1a
NASM    = nasm
LD      = ld
QEMU    = qemu-system-x86_64
IMAGE   = piOS.img
KERNEL  = piOS.bin
BOOT    = boot_loader.bin
LDSCRIPT= linker.ld
MEM_SIZE= 128
--- Source Files (51 files) ---
1. Kernel Core, Memory, and System Calls
CORE_OBJS = kernel.o gdt_idt.o vmem.o pager.o syscall.o timer_sched.o syscall_translator.o metrics.o
2. Hardware and I/O Drivers
DRIVER_OBJS = pci.o driver_manager.o disk_io.o ahci_driver.o input_manager.o mouse_driver.o serial_port.o usb_driver.o rtl8139_driver.o
3. Filesystems and Environment
FS_OBJS = ext2_driver.o journal.o registry.o boot_config.o devfs.o app_env.o
4. Graphics, Windows, and Text
GUI_OBJS = fb_manager.o fl.o fl_api.o vnc_server.o window_manager.o window_server.o taskbar.o start_menu.o
5. Internationalization and Text Stack
TEXT_OBJS = kbd_layout.o unicode.o i18n.o font_renderer.o
6. Process and Application Loading
APP_OBJS = task_manager.o pe_loader.o clr_host.o assembly_loader.o security.o threads.o
7. Applications and Networking
UTIL_OBJS = shell.o guest_loader.o net_stack.o tcp_ip.o zlib.o
Combine all object files
OBJECTS = $(CORE_OBJS) $(DRIVER_OBJS) $(FS_OBJS) $(GUI_OBJS) $(TEXT_OBJS) $(APP_OBJS) $(UTIL_OBJS)
.PHONY: all clean run upload
--- Default Target: Build the entire OS image ---
all: $(IMAGE)
@echo "=========================================="
@echo "  PI OS BUILD SUCCESSFUL"
@echo "  Version: $(BUILD_VERSION)"
@echo "=========================================="
--- Rule 1: Link all object files into the kernel binary (.bin) ---
$(KERNEL): $(OBJECTS) $(LDSCRIPT)
$(LD) -m elf_i386 -T $(LDSCRIPT) -o $(KERNEL) $(OBJECTS)
--- Rule 2: Create the final bootable image (.img) ---
$(IMAGE): $(KERNEL) $(BOOT)
cat $(BOOT) $(KERNEL) > $(IMAGE)
@echo "-> Image size check complete."
--- Rule 3: Compile all assembly files into object files (.o) ---
Generic rule to compile all .asm files, including the qemu config
%.o: %.asm qemu_config.inc
$(NASM) -f elf32 $< -o $@
--- Rule 4: Run the OS in QEMU ---
This uses the specific QEMU executable confirmed in Termux.
run: $(IMAGE)
@echo "-> Launching Pi OS in QEMU (VNC on :1, port 5901)..."
(QEMU) -drive format=raw,file=(IMAGE) -m (MEM_SIZE) -vnc :1 -name "Pi OS Kernel v(BUILD_VERSION)"
--- Rule 5: Clean up generated files ---
clean:
@echo "-> Cleaning up build artifacts..."
rm -f $(OBJECTS) $(KERNEL) $(IMAGE)
