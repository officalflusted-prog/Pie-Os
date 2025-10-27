; ----------------------------------------------------------------------
; File: driver_manager.asm
; Purpose: Centralized registration, lookup, and management of hardware drivers.
; ----------------------------------------------------------------------

bits 32

; --- Constants ---
MAX_DRIVERS equ 64
DRIVER_NAME_SIZE equ 16
DRIVER_STRUCT_SIZE equ 32 ; [Name, Type, Init_Func_Ptr, Read_Func_Ptr, IRQ]

; --- Global Data ---
driver_table times MAX_DRIVERS * DRIVER_STRUCT_SIZE db 0
driver_count db 0

; --- External Subroutines ---
; extern pci_enumerate_devices (to kick off device discovery)

; ----------------------------------------------------------------------
; Subroutine: driver_manager_init
; Initializes the system by scanning the hardware and loading default drivers.
; ----------------------------------------------------------------------
driver_manager_init:
    pushad
    
    ; 1. Clear the driver table
    
    ; 2. Run PCI enumeration to discover devices
    call pci_enumerate_devices
    
    ; (The pci_enumerate_devices routine will call driver_register for found devices)
    
    popad
    ret

; ----------------------------------------------------------------------
; Subroutine: driver_register
; Adds a newly discovered or loaded driver to the internal table.
; ----------------------------------------------------------------------
; Parameters:
;   ESI: Pointer to the initialized driver information structure
driver_register:
    pushad
    
    ; 1. Find a free slot in the driver_table
    mov al, [driver_count]
    cmp al, MAX_DRIVERS
    jge .error_max_drivers
    
    movzx ebx, al           ; EBX = Index
    mov edi, driver_table
    imul ebx, DRIVER_STRUCT_SIZE
    add edi, ebx            ; EDI points to the free slot
    
    ; 2. Copy driver information into the table
    mov ecx, DRIVER_STRUCT_SIZE / 4
    rep movsd               ; Copy the structure from ESI to EDI
    
    ; 3. Increment the driver count
    inc byte [driver_count]
    
.done:
    popad
    ret

.error_max_drivers:
    ; (Handle error)
    jmp .done

; ----------------------------------------------------------------------
; Subroutine: driver_find_by_type
; Looks up a driver instance by its functional type (e.g., DISK_IO, ETHERNET).
; ----------------------------------------------------------------------
; Parameters:
;   EAX: Driver Type ID (e.g., 1=DISK, 2=NET)
;
; Returns: EAX = Pointer to the driver structure in the table (0 if not found)
driver_find_by_type:
    ; 1. Loop through the driver_table
    ; 2. Compare the stored Driver Type field with EAX
    ; 3. Return the pointer to the structure on match
    ret

; ----------------------------------------------------------------------
; Subroutine: driver_call_read
; Abstraction layer: Calls the read function of a specific driver.
; ----------------------------------------------------------------------
; Parameters: EAX=Driver Pointer, EBX=LBA, etc. (Generic Disk Read Args)
driver_call_read:
    ; 1. EAX points to the driver structure.
    ; 2. Get the address of the read function: mov edi, [eax + Read_Func_Ptr_Offset]
    ; 3. Jump to the function: jmp edi
    ret
