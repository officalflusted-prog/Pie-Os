; ----------------------------------------------------------------------
; File: journal.asm
; Purpose: Filesystem Journaling (Write-Ahead Logging) for data integrity
; ----------------------------------------------------------------------

bits 32

; --- Constants ---
JOURNAL_BLOCK_START equ 0x2000    ; Starting LBA for the dedicated journal area
JOURNAL_ENTRY_SIZE equ 64         ; Fixed size for a journal entry (metadata operation)
MAX_JOURNAL_ENTRIES equ 256

; --- Journal Entry Structure (Simplified) ---
; [0-3]: Transaction ID (Unique ID for a set of operations)
; [4-7]: Operation Type (e.g., CREATE_FILE, DELETE_INODE, UPDATE_BLOCK)
; [8-11]: Target Inode Number
; [12-15]: Target Block Address (LBA)
; [16-19]: Data Block Address in RAM (for block data that needs writing)

; --- Global Data ---
current_transaction_id dd 1       ; Incremented for every new set of changes
journal_head_lba dd 0             ; Next free LBA in the journal area

; --- External Subroutines ---
; extern ata_write_sectors (from disk_io.asm)
; extern ata_read_sectors (for recovery)
; extern vmem_alloc_pages, vmem_free_pages

; ----------------------------------------------------------------------
; Subroutine: journal_init
; Initializes the journal system and checks for previous crashes.
; ----------------------------------------------------------------------
journal_init:
    pushad
    
    ; 1. Read the Journal Superblock (to find the last transaction ID, journal head)
    
    ; 2. Check for Incomplete Transactions (Recovery Check)
    ; If the last transaction block is incomplete:
    call journal_recover
    
    popad
    ret

; ----------------------------------------------------------------------
; Subroutine: journal_start_transaction
; Begins a new set of filesystem operations that must be atomic.
; ----------------------------------------------------------------------
; Returns: EAX = New Transaction ID
journal_start_transaction:
    pushad
    
    inc dword [current_transaction_id]
    mov eax, [current_transaction_id]
    
    popad
    ret

; ----------------------------------------------------------------------
; Subroutine: journal_log_metadata
; Records a single metadata change operation to the journal buffer in RAM.
; ----------------------------------------------------------------------
; Parameters: EAX=Operation Type, EBX=Target Inode, ECX=Target Block LBA
journal_log_metadata:
    pushad
    
    ; 1. Find the next free slot in the in-memory journal buffer
    ; ESI points to the free entry
    
    ; 2. Write the entry data
    mov edx, [current_transaction_id]
    mov [esi], edx              ; Transaction ID
    mov [esi + 4], eax          ; Operation Type
    mov [esi + 8], ebx          ; Target Inode
    mov [esi + 12], ecx         ; Target LBA
    
    popad
    ret

; ----------------------------------------------------------------------
; Subroutine: journal_commit
; Writes all logged entries to the journal disk area and then applies changes.
; ----------------------------------------------------------------------
; Steps (The core of Journaling):
; 1. Write Data Blocks (if any) to their final destination on disk.
; 2. Write the Journal Entries (Metadata) to the Journal area on disk. (Write-Ahead)
; 3. Write a COMMIT Record to the Journal. (Marks the transaction as complete)
; 4. Write the Actual Metadata (Inodes, Block Maps) to their final ext2 location.
; 5. Write a REVOKE Record to the Journal (Optional, marks journal space as free).
journal_commit:
    ; ... (Complex implementation)
    ret

; ----------------------------------------------------------------------
; Subroutine: journal_recover
; Replays the journal log after a detected crash (on journal_init).
; ----------------------------------------------------------------------
journal_recover:
    pushad
    
    ; 1. Scan the Journal area for the last complete COMMIT record.
    ; 2. Read all metadata operations from that point to the end of the log.
    ; 3. Re-apply those metadata operations to the ext2 filesystem structures.
    ; (This restores filesystem consistency.)
    
    popad
    ret
