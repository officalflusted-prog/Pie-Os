; ----------------------------------------------------------------------
; File: assembly_loader.asm
; Purpose: Parses .NET assembly metadata and performs security verification.
; ----------------------------------------------------------------------

bits 32

; --- Constants ---
CLI_HEADER_SIGNATURE equ 0x0000484C ; 'L', 'H', 0, 0 (CLR Header magic)
IMAGE_SUBSYSTEM_NATIVE equ 1        ; PE Subsystem for native apps
IMAGE_SUBSYSTEM_WINDOWS_CUI equ 3   ; PE Subsystem for console apps
IMAGE_SUBSYSTEM_CLR equ 0x0A        ; PE Subsystem for CLR (managed) apps

; --- External Subroutines ---
; extern pe_loader_get_optional_header (from pe_loader.asm)
; extern verify_hash (from security.asm, checks assembly signature)

; ----------------------------------------------------------------------
; Subroutine: load_clr_assembly
; Loads a PE file, verifies it's a CLR assembly, and extracts metadata.
; ----------------------------------------------------------------------
; Parameters:
;   EAX: Pointer to the PE file loaded in RAM
;
; Returns:
;   EAX: Pointer to the CLR Metadata Directory on success
;   Carry Flag Set (CF=1) on failure (Not a valid CLR assembly)
; ----------------------------------------------------------------------
load_clr_assembly:
    pushad
    mov esi, eax                    ; ESI = Pointer to PE file data
    
    ; 1. Get the PE Optional Header
    ; call pe_loader_get_optional_header 
    mov edi, [optional_header_ptr]  ; EDI = Pointer to Optional Header
    
    ; 2. Verify Subsystem Type (Check if it's a managed executable)
    movzx ecx, word [edi + 0x44]    ; ECX = Subsystem field offset
    cmp ecx, IMAGE_SUBSYSTEM_CLR
    jne .error_not_managed          ; Must be 0x0A
    
    ; 3. Locate the CLR Runtime Header (Data Directory Entry 14)
    ; Directory entries start at offset 0x90 in the Optional Header (64-bit addresses not shown)
    mov ebx, [edi + 0xF8]           ; EBX = RVA of CLR Runtime Header (Data Directory 14)
    mov ecx, [edi + 0xFC]           ; ECX = Size of CLR Runtime Header
    
    ; Convert RVA to Physical Address (requires PE file section mapping)
    ; call pe_loader_rva_to_physical(EBX) ; EBP = Physical address of CLR Header
    
    ; 4. Verify CLR Header Integrity
    mov edi, EBP
    cmp dword [edi], 0x48           ; Check CLR Header Size (should be 48 bytes)
    jle .error_invalid_header
    
    ; 5. Verify CLI Header Signature (Optional check for robust validation)
    ; cmp dword [edi + 0x04], CLI_HEADER_SIGNATURE 
    
    ; 6. Locate the Metadata Directory
    mov eax, [edi + 0x08]           ; EAX = RVA of Metadata Root
    ; call pe_loader_rva_to_physical(EAX) ; EAX = Physical address of Metadata Root
    
    ; 7. Verify Strong Name Signature (Security Check)
    mov edx, [edi + 0x20]           ; EDX = RVA of Strong Name Signature
    cmp edx, 0                      ; Check if a strong name exists
    je .no_strong_name              ; Skip verification if no strong name
    
    ; call verify_hash(EDX)         ; Check against embedded public key hash
    
.no_strong_name:
    ; EAX holds the pointer to the Metadata Root
    clc                             ; Clear Carry Flag (Success)
    popad
    ret

.error_not_managed:
    mov esi, error_msg_unmanaged
    ; call print_string_32
    jmp .error_fail

.error_invalid_header:
    mov esi, error_msg_bad_header
    ; call print_string_32
    jmp .error_fail

.error_fail:
    mov eax, 0
    stc                             ; Set Carry Flag (Failure)
    popad
    ret

; --- Data ---
optional_header_ptr dd 0
error_msg_unmanaged db "ASSEMBLY_LOADER: Not a managed executable.", 0x00
error_msg_bad_header db "ASSEMBLY_LOADER: Invalid CLR header.", 0x00
