; ----------------------------------------------------------------------
; File: ahci_driver.asm
; Purpose: Native 32-bit AHCI (SATA) Driver for high-speed disk I/O.
; ----------------------------------------------------------------------

bits 32

; --- Constants ---
AHCI_CAP_OFFSET equ 0x00      ; Host Capabilities Register
AHCI_PI_OFFSET equ 0x0C       ; Ports Implemented Register
AHCI_PORT_START equ 0x100     ; Start of port registers

; --- Global Data ---
ahci_hba_mem_base dd 0        ; The physical base address of the AHCI MMIO registers
ahci_port_command_list dd 0   ; Physical address of the command list (must be 1KB aligned)

; --- External Subroutines ---
; extern pci_find_device (from pci.asm)
; extern vmem_map_mmio (from vmem.asm, to map the physical base into kernel space)
; extern driver_register (from driver_manager.asm)

; ----------------------------------------------------------------------
; Subroutine: ahci_init
; Finds the AHCI controller via PCI and initializes its ports.
; ----------------------------------------------------------------------
ahci_init:
    pushad
    
    ; 1. Find AHCI via PCI (Class Code 01h, SubClass 06h, ProgIF 01h)
    ; call pci_find_device
    ; (EAX returns the physical MMIO Base Address)
    
    ; 2. Map the physical MMIO base into the kernel's virtual address space
    mov [ahci_hba_mem_base], eax
    ; call vmem_map_mmio (maps the range of registers)
    mov ebp, [ahci_hba_mem_base_virtual] ; EBP = Virtual Base Address
    
    ; 3. Enable AHCI (Set AE bit in HBA Global Host Control register)
    or dword [ebp + 0x04], 0x80000000 

    ; 4. Check Ports Implemented (PI) register
    mov eax, [ebp + AHCI_PI_OFFSET]
    
    ; 5. Loop through implemented ports (1 to 32)
    mov ecx, 0
.port_loop:
    cmp ecx, 32
    je .done_init
    
    bt eax, ecx                 ; Test if bit 'ecx' is set in EAX (PI register)
    jnc .next_port              ; If not set, port is not implemented
    
    ; Initialize the port (Set CLO, ST bits, setup command lists, etc.)
    call .port_reset_and_start
    
.next_port:
    inc ecx
    jmp .port_loop

.done_init:
    ; Register the AHCI driver instance
    ; call driver_register
    
    popad
    ret

; ----------------------------------------------------------------------
; Subroutine: ahci_read_sectors_ncq
; Submits a read command using Native Command Queuing (NCQ).
; ----------------------------------------------------------------------
; Parameters: EAX=Port ID, EBX=LBA, ECX=Count, EDI=Destination Buffer
ahci_read_sectors_ncq:
    ; 1. Find a free command slot in the port's command list.
    ; 2. Build the Command Header and Command FIS (Frame Information Structure).
    ; 3. Write PRDT (Physical Region Descriptor Table) entries (map user buffer).
    ; 4. Issue the command by setting the respective bit in the Command Issue register.
    ; 5. Wait for the command to complete or time out.
    ret
