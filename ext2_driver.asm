; ----------------------------------------------------------------------
; File: ext2_driver.asm
; Purpose: Native 32-bit Driver for the ext2 Filesystem
; ----------------------------------------------------------------------

bits 32

; --- Constants for ext2 Structure ---
EXT2_SUPER_BLOCK_LBA equ 2        ; Superblock starts at LBA 2 (sector 1024)
EXT2_S_MAGIC equ 0xEF53           ; Magic number for ext2 (must be present in superblock)
INODE_SIZE equ 128                ; Size of a standard ext2 inode (bytes)

; --- Global Data (Loaded from Superblock) ---
ext2_s_inodes_count dd 0          ; Total number of inodes
ext2_s_blocks_per_group dd 0      ; Blocks per group
ext2_s_inode_size dw 0            ; Bytes per inode

; --- External Subroutines ---
; extern ata_read_sectors (from disk_io.asm)
; extern vmem_alloc_pages (for block buffers)

; ----------------------------------------------------------------------
; Subroutine: ext2_init
; Initializes the driver and reads the Superblock metadata.
; ----------------------------------------------------------------------
ext2_init:
    pushad
    
    ; 1. Allocate a buffer for the Superblock
    ; mov edi, [superblock_buffer] 
    
    ; 2. Read the Superblock (always starts at LBA 2 / sector 1024)
    mov eax, EXT2_SUPER_BLOCK_LBA
    mov ecx, 2                  ; Read 2 sectors (1KB)
    mov edi, [superblock_buffer] ; Destination
    call ata_read_sectors
    
    ; 3. Verify the Magic Number
    cmp word [edi + 0x38], EXT2_S_MAGIC ; Offset 0x38 is s_magic
    jne .error_not_ext2                 ; If no match, it's not an ext2 partition
    
    ; 4. Load Critical Metadata into Global Data
    mov eax, [edi + 0x20]       ; s_blocks_per_group
    mov [ext2_s_blocks_per_group], eax
    
    movzx ax, word [edi + 0x58] ; s_inode_size
    mov [ext2_s_inode_size], ax
    
    jmp .done

.error_not_ext2:
    ; (Print error and fallback to fat12.asm or halt)
    
.done:
    popad
    ret

; ----------------------------------------------------------------------
; Subroutine: ext2_read_inode
; Calculates the location of an Inode and loads it from disk.
; ----------------------------------------------------------------------
; Parameters:
;   EAX: Inode number to read
;   EDI: Destination buffer (at least INODE_SIZE bytes)
ext2_read_inode:
    pushad
    
    ; 1. Calculate the Block Group (BG) containing the Inode
    mov ebx, eax
    dec ebx                     ; Inode numbers start at 1
    
    mov ecx, [ext2_s_inodes_per_group] ; Inodes per group (must be loaded earlier)
    div ecx                     ; EAX = Block Group Index, EDX = Inode Index within the group
    
    ; 2. Get the Block Group Descriptor Table (BGDT) address
    ; (BGDT location is derived from the Superblock)
    
    ; 3. Read the BG Descriptor to find the Inode Table Block
    ; (This is complex I/O: read BGDT block, find address of Inode Table)
    
    ; 4. Calculate the Inode's LBA
    ; LBA = (Inode Table Start Block) + (Inode Index * Inode Size / Block Size)
    ; 5. Read the required sectors using ata_read_sectors into EDI
    
    popad
    ret

; ----------------------------------------------------------------------
; Subroutine: ext2_lookup
; Searches a directory block for a filename.
; ----------------------------------------------------------------------
; Parameters:
;   EAX: Directory Inode Number
;   ESI: Pointer to the null-terminated filename string
;
; Returns:
;   EAX: Inode number of the found file (0 if not found)
ext2_lookup:
    pushad
    
    ; 1. Read the Directory Inode (using ext2_read_inode)
    
    ; 2. Loop through the Inode's data blocks (I_block[0] is the first data block)
    ; (This handles single, double, and triple indirect blocks, making it complex)
    
    ; 3. Search the directory data blocks for a matching filename
    ; (The directory entry structure contains the inode number and file name length)
    
    popad
    ret

; --- Data Buffer ---
superblock_buffer times 1024 db 0 ; 1KB buffer for the superblock
