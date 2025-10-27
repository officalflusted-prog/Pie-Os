; ----------------------------------------------------------------------
; File: devfs.asm
; Purpose: Virtual Filesystem for exposing device nodes (e.g., /dev/tty0, /dev/ata0).
; ----------------------------------------------------------------------

bits 32

; --- Constants ---
DEVFS_MAX_NODES equ 64
NODE_NAME_SIZE equ 16
NODE_STRUCT_SIZE equ 32 ; [Name, Type, Major/Minor, Read_Func_Ptr, Write_Func_Ptr]

; --- Device Node Types ---
DEVFS_TYPE_BLOCK equ 0x01 ; Block devices (disks, partitions)
DEVFS_TYPE_CHAR equ 0x02  ; Character devices (console, mouse, serial)

; --- Global Data (In-Memory Node Table) ---
devfs_node_table times DEVFS_MAX_NODES * NODE_STRUCT_SIZE db 0
devfs_node_count db 0

; --- External Subroutines ---
; extern task_manager_get_fd (to manage the process's file descriptor table)
; extern unicode_compare_ci (for case-insensitive lookups)

; ----------------------------------------------------------------------
; Subroutine: devfs_init
; Initializes the device filesystem with mandatory system nodes.
; ----------------------------------------------------------------------
devfs_init:
    pushad
    
    ; 1. Register the console device
    mov esi, dev_tty0_name
    mov eax, DEVFS_TYPE_CHAR
    mov ebx, console_read_func ; Read function address
    mov ecx, console_write_func ; Write function address
    call devfs_register_node
    
    ; 2. Register the main disk partition
    mov esi, dev_ata0_name
    mov eax, DEVFS_TYPE_BLOCK
    mov ebx, ahci_read_sectors_ncq ; Read function address (or wrapper)
    mov ecx, ahci_write_sectors_ncq ; Write function address (or wrapper)
    call devfs_register_node
    
    ; 3. Register the mouse/input device
    ; ...
    
    popad
    ret

; ----------------------------------------------------------------------
; Subroutine: devfs_register_node
; Adds a new device node to the in-memory table.
; ----------------------------------------------------------------------
; Parameters:
;   ESI: Pointer to the node name string (e.g., "tty0")
;   EAX: Node Type (DEVFS_TYPE_BLOCK or CHAR)
;   EBX: Read Function Pointer
;   ECX: Write Function Pointer
devfs_register_node:
    pushad
    
    ; 1. Find a free slot in the devfs_node_table
    movzx edx, byte [devfs_node_count]
    mov edi, devfs_node_table
    imul edx, NODE_STRUCT_SIZE
    add edi, edx            ; EDI points to the free slot
    
    ; 2. Copy the name and setup the structure
    ; (Copy ESI string into [EDI])
    mov [edi + NODE_NAME_SIZE], eax ; Store Type
    mov [edi + NODE_NAME_SIZE + 4], ebx ; Store Read Func Ptr
    mov [edi + NODE_NAME_SIZE + 8], ecx ; Store Write Func Ptr
    
    inc byte [devfs_node_count]
    
    popad
    ret

; ----------------------------------------------------------------------
; Subroutine: devfs_lookup
; Searches the node table for a given name (used when opening a file like /dev/tty0).
; ----------------------------------------------------------------------
; Parameters:
;   ESI: Pointer to the null-terminated node name string
;
; Returns: EAX = Pointer to the device node structure (0 if not found)
devfs_lookup:
    pushad
    
    mov ebx, 0
    movzx ecx, byte [devfs_node_count]
    
.search_loop:
    cmp ebx, ecx
    je .not_found
    
    mov edx, devfs_node_table
    imul ebx, NODE_STRUCT_SIZE
    add edx, ebx            ; EDX = Start of current node struct
    
    ; Compare ESI (input name) with [EDX] (node name)
    mov edi, edx
    call unicode_compare_ci ; Assumes ESI, EDI are arguments for compare
    cmp eax, 0              ; 0 means match
    je .found
    
    inc ebx
    jmp .search_loop

.found:
    mov eax, edx            ; Return pointer to the structure
    jmp .done

.not_found:
    mov eax, 0              ; Return 0
    
.done:
    popad
    ret

; --- Data ---
dev_tty0_name db "tty0", 0x00
dev_ata0_name db "ata0", 0x00

; --- External Function Pointers (Placeholder) ---
; These would point to the read/write entry points in other drivers
console_read_func dd 0
console_write_func dd 0
