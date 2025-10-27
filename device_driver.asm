; ----------------------------------------------------------------------
; File: device_driver.asm
; Purpose: PCI Device Enumeration and Generic Driver Loader for PieOS
; ----------------------------------------------------------------------

bits 16

; --- Constants for PCI Configuration Access Mechanism (Type 1) ---
; PCI configuration space is accessed via two I/O ports:
PCI_CONFIG_ADDRESS_PORT equ 0xCF8
PCI_CONFIG_DATA_PORT    equ 0xCFC

; --- Data Section ---
; Stores information about a found device
pci_device_info:
    .vendor_id  dw 0    ; 2 bytes
    .device_id  dw 0    ; 2 bytes
    .class_code db 0    ; 1 byte (e.g., 0x02 for Network, 0x03 for Display)
    .subclass_code db 0 ; 1 byte
    .bus_num    db 0    ; 1 byte
    .slot_num   db 0    ; 1 byte
    .func_num   db 0    ; 1 byte

; Global list of found PCI devices (max 20 devices, 8 bytes per entry)
pci_device_list times 20 * 8 db 0
pci_device_count db 0

; ----------------------------------------------------------------------
; Subroutine: pci_enumerate
; Scans the entire PCI bus (Bus 0-255, Device 0-31, Function 0-7)
; ----------------------------------------------------------------------
; Returns:
;   pci_device_count updated with the total number of devices found.
; ----------------------------------------------------------------------
pci_enumerate:
    pusha
    
    mov byte [pci_device_count], 0
    mov bh, 0x00            ; Bus Number (0 to 255)
.bus_loop:
    mov bl, 0x00            ; Slot Number (Device 0 to 31)
.slot_loop:
    mov cl, 0x00            ; Function Number (0 to 7)
.func_loop:
    ; 1. Construct the PCI Address DWORD
    ; Address structure: Enable Bit (31) | Reserved (30:24) | Bus (23:16) | Slot (15:11) | Function (10:8) | Register (7:2) | 00 (1:0)
    
    ; Setup the CONFIG_ADDRESS register (mov edx, address)
    ; We are looking for Register 0x00 (Vendor/Device ID)
    push cx
    call .construct_pci_address
    pop cx
    
    ; 2. Read the Vendor/Device ID
    call .pci_read_dword    ; Reads the 4-byte Vendor/Device ID into EAX
    
    cmp ax, 0xFFFF          ; Check if Vendor ID (AX) is 0xFFFF (device does not exist)
    je .next_func           ; If so, skip this function
    cmp ax, 0x0000          ; Check if Vendor ID (AX) is 0x0000
    je .next_func           ; If so, skip this function
    
    ; 3. Device Found! Store the location (Bus/Slot/Func) and IDs.
    ; This is where more details (Class Code) would be read and stored.
    
    call .store_pci_device
    
.next_func:
    inc cl                  ; Function++
    cmp cl, 0x08
    jl .func_loop           ; Loop if Function < 8

    inc bl                  ; Slot++
    cmp bl, 0x20
    jl .slot_loop           ; Loop if Slot < 32

    inc bh                  ; Bus++
    cmp bh, 0xFF
    jle .bus_loop           ; Loop if Bus < 256 (or less, depending on BIOS limits)

    popa
    ret

; ----------------------------------------------------------------------
; Helper: .construct_pci_address
; Constructs the 32-bit PCI configuration address in EAX
; ----------------------------------------------------------------------
.construct_pci_address:
    ; Input: BH=Bus, BL=Slot, CL=Func. (Uses hardcoded Register 0x00)
    ; Output: EAX = PCI Configuration Address
    push cx
    push dx
    
    ; EAX = (1 << 31) | (Bus << 16) | (Slot << 11) | (Func << 8) | (Register << 2)
    mov eax, 0x80000000     ; Enable Bit
    mov al, cl              ; EAX = Func number
    shl eax, 8              ; EAX = Func << 8
    
    mov dl, bl              ; DL = Slot number
    shl edx, 11             ; EDX = Slot << 11
    or eax, edx             ; Add Slot to EAX
    
    mov dl, bh              ; DL = Bus number
    shl edx, 16             ; EDX = Bus << 16
    or eax, edx             ; Add Bus to EAX
    
    pop dx
    pop cx
    ret

; ----------------------------------------------------------------------
; Helper: .pci_read_dword
; Writes address to 0xCF8 and reads the result from 0xCFC.
; ----------------------------------------------------------------------
.pci_read_dword:
    ; Input: EAX = PCI Configuration Address
    ; Output: EAX = 32-bit Data read from 0xCFC
    push dx
    
    out PCI_CONFIG_ADDRESS_PORT, eax ; Write the address
    in eax, PCI_CONFIG_DATA_PORT     ; Read the data
    
    pop dx
    ret

; ----------------------------------------------------------------------
; Subroutine: load_driver
; Placeholder: Attempts to load a driver file for a discovered device.
; ----------------------------------------------------------------------
; Parameters:
;   AX: Index into pci_device_list
load_driver:
    pusha
    
    ; 1. Retrieve Vendor/Device ID from pci_device_list[AX].
    ; 2. Construct a driver filename (e.g., "DRV_10DE_0123.BIN").
    ; 3. call load_file (from fat12.asm) to load the driver into memory.
    ; 4. Jump to the driver's entry point to initialize the hardware.
    
    popa
    ret
