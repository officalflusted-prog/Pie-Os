; ----------------------------------------------------------------------
; File: qemu_config.inc
; Purpose: Defines constants and settings optimized for the QEMU emulator.
; ----------------------------------------------------------------------

; --- Hardware / Emulation Constants ---

; ACPI/APIC: QEMU usually supports APIC, but we default to PIC for simplicity.
; Define a flag to use the simpler PIC interrupt controller.
USE_LEGACY_PIC equ 1

; QEMU's default clock speed for the PIT (Programmable Interval Timer) is standard.
PIT_DIVISOR equ 1193180 / 100       ; Set timer to 100Hz (10ms period)

; VGA/Framebuffer: QEMU's standard VGA is compatible, but we can enable a flag
; if we want to force QEMU's extended VBE modes.
FORCE_QEMU_VBE equ 0

; --- Debugging Flags ---

; Serial Port: QEMU often redirects the first serial port (COM1) to the host console,
; which is essential for kernel debugging output (e.g., printing log messages).
SERIAL_PORT_COM1 equ 0x3F8

; --- Memory Layout ---

; QEMU usually provides a predictable memory map.
KERNEL_LOG_ADDRESS equ 0x1000000    ; Start kernel log buffer here (16MB mark)

; --- QEMU Specific I/O Ports ---

; QEMU "magic" shutdown/reboot port (often used by OS developers)
QEMU_SHUTDOWN_PORT equ 0x604        ; Standard port for fast shutdown
QEMU_REBOOT_PORT equ 0x642          ; Standard port for fast reboot
