; ----------------------------------------------------------------------
; File: pe_loader.asm
; Purpose: Loads and prepares a Portable Executable (.EXE) file for execution
; ----------------------------------------------------------------------

bits 32
; NOTE: This code executes in 32-bit Protected Mode.

; --- PE File Structure Constants (Simplified) ---
PE_SIGNATURE_OFFSET equ 0x3C     ; Offset to the PE signature from the start of the file
PE_SIGNATURE        equ 0x4550   ; 'PE\0\0' (E, P, 0, 0 in little-endian)
IMAGE_FILE_HEADER_SIZE equ 20
IMAGE_OPTIONAL_HEADER_SIZE equ 224 ; Varies, but 224 is common

; --- External Subroutines (from kernel32.asm/fat12.asm) ---
; extern load_file, allocate_memory, print_string_32

; ----------------------------------------------------------------------
; Subroutine: load_pe_file
; Parses, loads, and prepares a PE file (like a .NET executable)
; ----------------------------------------------------------------------
; Parameters:
;   EAX: Pointer to the file data loaded from disk (in RAM)
;
; Returns:
;   EAX: Entry Point Address (where execution should begin)
;   Carry Flag Set (CF=1) on failure
; ----------------------------------------------------------------------
load_pe_file:
    pushad              ; Save all 32-bit general registers
    
    mov esi, eax        ; ESI = Pointer to the raw file data
    
    ; 1. Check for the MS-DOS Stub (Find the PE Signature Offset)
    movzx ebx, word [esi + PE_SIGNATURE_OFFSET] ; EBX = Offset from file start
    
    ; 2. Check for the PE Signature ("PE\0\0")
    cmp dword [esi + ebx], PE_SIGNATURE         ; Compare with 'P', 'E', 0, 0
    jne .error_invalid_pe
    
    add ebx, 4          ; EBX now points to the IMAGE_FILE_HEADER
    
    ; 3. Parse the IMAGE_FILE_HEADER
    mov ecx, ebx        ; ECX = Pointer to the File Header
    add ebx, IMAGE_FILE_HEADER_SIZE ; EBX now points to the Optional Header
    
    ; The File Header tells us the number of sections (important for the next step)
    movzx edx, word [ecx + 2] ; EDX = NumberOfSections
    
    ; 4. Parse the IMAGE_OPTIONAL_HEADER
    mov ecx, ebx        ; ECX = Pointer to the Optional Header
    
    ; Get the Entry Point
    mov eax, [ecx + 0x10] ; EAX = AddressOfEntryPoint (Relative Virtual Address - RVA)
    
    ; Get the Image Base Address (where the PE file expects to be loaded in memory)
    mov ebp, [ecx + 0x1C] ; EBP = ImageBase
    add eax, ebp          ; EAX = Final Virtual Entry Point
    
    ; 5. Load Sections into Memory (The most critical part)
    add ebx, IMAGE_OPTIONAL_HEADER_SIZE ; EBX now points to the Section Headers
    
    mov esi, ebx        ; ESI = Pointer to the first Section Header
.section_loop:
    cmp edx, 0
    je .loading_done    ; All sections loaded
    
    ; Get VIRTUAL ADDRESS (where the section should go)
    mov edi, [esi + 0xC]    ; EDI = VirtualAddress
    add edi, ebp            ; EDI = Final Physical/Virtual Address
    
    ; Get RAW DATA ADDRESS (where the data is in the file buffer)
    mov ebx, [esi + 0x14]   ; EBX = PointerToRawData
    add ebx, [eax_original_file_base] ; Adjust with the file start address
    
    ; Get SIZE OF RAW DATA (how much data to copy)
    mov ecx, [esi + 0x10]   ; ECX = SizeOfRawData
    
    ; Allocate memory (if necessary) and copy data
    ; call allocate_memory
    mov edx, edi            ; Destination address
    mov edi, ebx            ; Source address (in file buffer)
    ; rep movsb               ; Copy ECX bytes from [EDI] to [EDX]
    
    add esi, 0x28           ; Advance ESI to the next 40-byte Section Header
    dec edx
    jmp .section_loop

.loading_done:
    popad
    
    ; EAX holds the Entry Point Address
    clc                 ; Clear Carry Flag (Success)
    ret

.error_invalid_pe:
    ; (print error message)
    popad
    stc                 ; Set Carry Flag (Failure)
    mov eax, 0          ; Return 0
    ret
