; ----------------------------------------------------------------------
; File: deflate.asm
; Purpose: Implements the DEFLATE algorithm (required for .ZIP file support)
; ----------------------------------------------------------------------

bits 32
; NOTE: This code executes in 32-bit Protected Mode.

; --- Data Section: Huffman Tables ---
; DEFLATE uses three sets of Huffman codes:
; 1. Literal/Length codes (286 entries)
; 2. Distance codes (30 entries)
; 3. Code Length codes (19 entries)
literal_length_codes times 286 * 2 db 0 ; Placeholder for pre-calculated codes
distance_codes times 30 * 2 db 0         ; Placeholder for pre-calculated codes

; --- External Subroutines (from lib.asm/kernel32.asm) ---
; extern allocate_memory, print_string_32

; ----------------------------------------------------------------------
; Subroutine: deflate_decompress
; Main entry point to decompress a block of DEFLATE data.
; ----------------------------------------------------------------------
; Parameters:
;   ESI: Pointer to the compressed source data (ZIP file's data section)
;   EDI: Pointer to the destination buffer (uncompressed output)
;   ECX: Size of the compressed data block
;
; Returns:
;   EAX: Size of the uncompressed data
;   Carry Flag Set (CF=1) on decompression error
; ----------------------------------------------------------------------
deflate_decompress:
    pushad
    
    ; 1. Read Block Header
    ; The first 3 bits indicate: Final block flag, and Block Type (Fixed, Dynamic, or Uncompressed)
    
.block_loop:
    ; Read the 'BFINAL' bit (0=More blocks, 1=Last block)
    ; Read the 'BTYPE' bits (00=Uncompressed, 01=Fixed Huffman, 10=Dynamic Huffman)

    ; 2. Set up Huffman Tables based on BTYPE
    cmp ebx, 01             ; Check for Fixed Huffman tables
    je .fixed_huffman       
    
    cmp ebx, 10             ; Check for Dynamic Huffman tables
    je .dynamic_huffman_setup ; Needs to read the code lengths from the input stream
    
    ; Handle Uncompressed Block (BTYPE=00): simply copy bytes
    jmp .uncompressed_copy
    
.fixed_huffman:
    ; Load the pre-calculated Fixed Huffman tables into working memory
    jmp .decode_data
    
.dynamic_huffman_setup:
    ; (Complex: Requires reading bitstream to build the tables on the fly)
    jmp .decode_data

.decode_data:
    ; 3. Main Decoding Loop
    ; Loop until EBLOCK is reached
.decode_symbol:
    ; a. Read bits from the input stream and decode using the Literal/Length Huffman table
    ;    EAX = decoded symbol (0-285)
    
    ; b. Handle Symbol Type:
    cmp eax, 256            ; 256 is the end-of-block (EBLOCK) symbol
    je .end_of_block
    
    cmp eax, 257            ; 257 is the start of a Length/Distance pair
    jl .literal_copy        ; Literal byte (0-255)
    
    ; --- LZ77 Back-Reference ---
    ; Symbol is a Length code (257-285)
    
    ; c. Decode Length: Find the match length using the Length table (EAX)
    mov ebp, eax            ; EBP = Match Length
    
    ; d. Decode Distance: Read bits and decode using the Distance Huffman table
    ;    EDX = Distance code
    
    ; e. Perform Copy: Copy EBP bytes from [EDI - EDX] to [EDI]
    ;    (This is the LZ77 back-reference that makes compression effective)
    
    jmp .decode_symbol
    
.literal_copy:
    ; Copy the literal byte (0-255) to the output buffer
    mov [edi], al           ; AL holds the literal byte
    inc edi                 ; Advance destination pointer
    jmp .decode_symbol

.end_of_block:
    ; Check BFINAL flag. If not set, continue to the next block.
    jmp .block_loop         ; Go to next block

.uncompressed_copy:
    ; (Simpler logic: Read 4 bytes for LEN, NLEN, and then copy LEN bytes)
    ; (Skip all Huffman logic for this block)
    jmp .block_loop
    
.final_done:
    ; EAX = total uncompressed size (EDI - initial_EDI)
    clc                     ; Clear Carry Flag (Success)
    popad
    ret

; ----------------------------------------------------------------------
; Subroutine: zip_file_reader
; Placeholder for the higher-level function that parses the ZIP file structure.
; ----------------------------------------------------------------------
zip_file_reader:
    ; 1. Locate the Central Directory File Header (CDFH) or Local File Header (LFH).
    ; 2. Read metadata: Filename, Compressed Size, Uncompressed Size, and CRC-32.
    ; 3. Call deflate_decompress on the file's data section.
    ret
