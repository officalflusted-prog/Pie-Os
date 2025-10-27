; ----------------------------------------------------------------------
; File: pager.asm
; Purpose: Implements Demand Paging and Swapping for Virtual Memory
; ----------------------------------------------------------------------

bits 32

; --- Constants ---
PAGE_SIZE equ 4096              ; 4KB pages
SWAP_PARTITION_START equ 0x100  ; Starting LBA of the dedicated swap partition
SWAP_SLOT_SIZE equ 4            ; 4 bytes per entry in the swap index table

; --- Global Data ---
swap_index_table_base dd 0      ; Base address of the table mapping VAs to swap locations
next_free_swap_page dd 0        ; Counter for the next free page on the swap partition

; --- External Subroutines ---
; extern ata_read_sectors, ata_write_sectors (from disk_io.asm)
; extern vmem_map_page, vmem_unmap_page (from vmem.asm)
; extern vmem_alloc_physical_frame (from vmem.asm)
; extern task_manager_get_active_task_id (for per-process swapping)

; ----------------------------------------------------------------------
; Subroutine: handle_page_fault_swap
; The core of demand paging. Called by the Exception Handler on a Page Fault.
; ----------------------------------------------------------------------
; Parameters:
;   EAX: The faulting address (from CR2)
;   EBX: The error code (read from the stack)
;
; Returns:
;   EAX: 0 on success (page loaded), -1 on fatal error.
; ----------------------------------------------------------------------
handle_page_fault_swap:
    pushad
    
    ; 1. Determine the Virtual Page Address (VPA)
    mov ebx, eax
    shr eax, 12                 ; EAX = VPA (Faulting address / 4096)
    shl eax, 12                 ; EAX = Canonical start address of the page
    
    ; 2. Check the Page Table Entry (PTE) for the 'Present' bit
    ; (This involves looking up the PDE and then the PTE using the kernel's mapping)
    ; If the PTE indicates the page is 'Not Present', we need to load it.
    
    ; 3. Check for the 'Swapped' Flag in the PTE (a custom bit we reserve)
    ; If the flag is set, the page is on the disk (Swapped-In operation needed).
    
    mov edi, [pte_address]      ; EDI points to the Page Table Entry
    test dword [edi], 0x002     ; Example: Check a reserved bit for 'swapped'
    jnz .page_is_on_disk        ; If the swap flag is set
    
    ; --- Case 1: Zero-Fill Page (First Time Access) ---
    ; Just allocate a new physical frame and map it.
    call vmem_alloc_physical_frame ; EBP = New Physical Frame Address
    mov ecx, EAX                ; ECX = VPA
    mov edx, EBP                ; EDX = PFA
    call vmem_map_page          ; Map the new frame (VPA -> PFA)
    
    ; (Need to zero-fill the frame before returning)
    jmp .success

.page_is_on_disk:
    ; --- Case 2: Swapped-In Page (Load from Disk) ---
    
    ; a. Look up the Swap Location
    ; (Find the entry in the swap_index_table_base for this VPA)
    mov esi, [swap_index_table_base]
    ; (Calculation: Add VPA offset to ESI)
    
    mov ebx, [esi]              ; EBX = LBA of the page on the swap partition
    add ebx, SWAP_PARTITION_START ; EBX = Final physical LBA
    
    ; b. Allocate a Physical Frame
    call vmem_alloc_physical_frame ; EBP = New Physical Frame Address
    
    ; c. Read the page from the swap disk
    mov eax, ebx                ; EAX = Starting LBA
    mov ecx, 1                  ; ECX = 1 sector
    mov edi, EBP                ; EDI = Destination (the new physical frame)
    call ata_read_sectors       ; Read 4KB (8 sectors) from the swap partition
    
    ; d. Update the Page Table Entry (PTE)
    mov ecx, EAX                ; ECX = VPA
    mov edx, EBP                ; EDX = PFA
    call vmem_map_page          ; Map the new frame (VPA -> PFA) and set 'Present' bit
    
.success:
    ; Invalidate the TLB entry for the newly mapped page
    invlpg [eax]                ; Invalidate the VPA (EAX)
    
    mov eax, 0                  ; Success
    jmp .done

.done:
    popad
    ret

; ----------------------------------------------------------------------
; Subroutine: swap_out_page
; Writes a page from RAM to the swap disk and marks the PTE as 'Swapped'.
; ----------------------------------------------------------------------
swap_out_page:
    pushad
    
    ; 1. Find a Victim Page (e.g., using a simple circular buffer or LRU algorithm)
    mov ebx, [victim_page_vpa]  ; EBX = VPA of the page to swap out
    
    ; 2. Allocate a Swap Slot
    mov eax, [next_free_swap_page]
    mov [next_free_swap_page], eax ; Claim the slot and increment the counter
    
    mov esi, SWAP_PARTITION_START
    add esi, eax                ; ESI = Final LBA on the swap partition
    
    ; 3. Write the Page to Disk
    mov eax, esi                ; EAX = Starting LBA
    mov ecx, 8                  ; ECX = 8 sectors (4KB)
    ; (Need to get the PFA for the VPA in EBX)
    mov edi, [pfa_of_victim_page] ; EDI = Source physical address
    call ata_write_sectors
    
    ; 4. Update and Unmap
    ; a. Store the LBA (ESI) in the swap_index_table
    ; b. call vmem_unmap_page (to clear the 'Present' bit, set the 'Swapped' bit)

    popad
    ret
