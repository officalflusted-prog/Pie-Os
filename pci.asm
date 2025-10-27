; ----------------------------------------------------------------------
; File: pci.asm
; Purpose: Driver to enumerate and configure PCI devices.
; ----------------------------------------------------------------------

bits 32

; --- Constants ---
PCI_CONFIG_ADDRESS_PORT equ 0xCF8  ; PCI Configuration Address Register
PCI_CONFIG_DATA_PORT equ 0xCFC     ; PCI Configuration Data Register

; --- External Subroutines ---
; extern driver_register (from driver_manager.asm)
; extern print_string_32 (for debugging)

; ----------------------------------------------------------------------
; Subroutine: pci_read_config_dword
; Reads a 32-bit value from a device's PCI Configuration Space.
; ----------------------------------------------------------------------
; Parameters:
;   EAX: PCI Address (Bus:Device:Function) encoded 31-0 (ENABLE_BIT | BUS | DEV | FUNC | OFFSET)
;
; Returns:
;   EAX: The 32-bit value read from the register
; ----------------------------------------------------------------------
pci_read_config_dword:
    push ebx
    
    ; 1. Write the target address to the CONFIG_ADDRESS register
    mov dx, PCI_CONFIG_ADDRESS_PORT
    out dx, eax             ; EAX already holds the encoded PCI address
    
    ; 2. Read the data from the CONFIG_DATA register
    mov dx, PCI_CONFIG_DATA_PORT
    in eax, dx              ; EAX now holds the 32-bit value
    
    pop ebx
    ret

; ----------------------------------------------------------------------
; Subroutine: pci_make_address
; Helper to construct the 32-bit PCI address register value.
; ----------------------------------------------------------------------
; Parameters:
;   AL: Bus, AH: Device, BL: Function, CL: Register Offset (0x00, 0x04, ...)
;
; Returns: EAX = Encoded PCI Address
; ----------------------------------------------------------------------
pci_make_address:
    ; EAX = 0x80000000 (Enable Bit)
    mov eax, 0x80000000 
    
    ; EAX |= (Bus << 16)
    movzx edx, al           ; EDX = Bus
    shl edx, 16
    or eax, edx
    
    ; EAX |= (Device << 11)
    movzx edx, ah           ; EDX = Device
    shl edx, 11
    or eax, edx
    
    ; EAX |= (Function << 8)
    movzx edx, bl           ; EDX = Function
    shl edx, 8
    or eax, edx
    
    ; EAX |= (Register Offset)
    movzx edx, cl           ; EDX = Offset
    or eax, edx
    
    ret

; ----------------------------------------------------------------------
; Subroutine: pci_enumerate_devices
; Scans all possible Bus/Device/Function combinations to find hardware.
; ----------------------------------------------------------------------
pci_enumerate_devices:
    pushad
    
    mov ebx, 0              ; EBX = Bus Counter (0-255)
.bus_loop:
    cmp ebx, 255
    jg .end_enumeration
    
    mov ecx, 0              ; ECX = Device Counter (0-31)
.device_loop:
    cmp ecx, 31
    jg .next_bus
    
    mov edx, 0              ; EDX = Function Counter (0-7)
.function_loop:
    cmp edx, 7
    jg .next_device
    
    ; 1. Construct address for Vendor ID (Offset 0x00)
    push ebx
    push ecx
    push edx
    mov al, bl              ; Bus
    mov ah, cl              ; Device
    mov bl, dl              ; Function
    mov cl, 0x00            ; Register Offset (Vendor ID)
    call pci_make_address   ; EAX = Encoded address
    
    call pci_read_config_dword ; EAX = Vendor ID | Device ID
    pop edx
    pop ecx
    pop ebx
    
    ; 2. Check for device existence
    cmp word ax, 0xFFFF     ; Vendor ID = 0xFFFF means no device
    je .next_function
    cmp word ax, 0x0000     ; Vendor ID = 0x0000 also usually means no device
    je .next_function
    
    ; --- Device Found! ---
    
    ; 3. Read Class Code and Subsystem Info (to identify the driver needed)
    ; (Requires more calls to pci_read_config_dword at different offsets)
    
    ; 4. Read the Base Address Registers (BARs) (Offsets 0x10 to 0x24)
    ; (BARs contain the I/O port or MMIO address for the driver to use)
    
    ; 5. Register the device with the Driver Manager
    ; mov esi, [device_info_struct]
    ; call driver_register
    
.next_function:
    inc edx
    jmp .function_loop

.next_device:
    inc ecx
    jmp .device_loop

.next_bus:
    inc ebx
    jmp .bus_loop

.end_enumeration:
    popad
    ret
