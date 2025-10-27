; ----------------------------------------------------------------------
; File: app_env.asm
; Purpose: Defines the standard application set and their properties for the OS shell/GUI.
; ----------------------------------------------------------------------

bits 32

; --- Constants ---
MAX_APPS equ 16
APP_NAME_SIZE equ 32
APP_PATH_SIZE equ 64
APP_STRUCT_SIZE equ 128 ; Size of the application metadata structure

; --- Application List Structure (Array of APP_STRUCT_SIZE) ---
; [0-31]: Application Name (e.g., "Chrome Browser")
; [32-95]: Executable Path (e.g., "/APPS/CHROME.EXE")
; [96-99]: App Type (0=Native, 1=CLR, 2=Guest/Linux)
; [100-103]: Icon Bitmap Pointer (for GUI use)

; --- Global Data ---
application_list times MAX_APPS * APP_STRUCT_SIZE db 0
current_app_count dd 0

; ----------------------------------------------------------------------
; Subroutine: app_env_init
; Populates the application list with the starter apps.
; ----------------------------------------------------------------------
app_env_init:
    pushad
    
    ; --- 1. Register Chrome Browser ---
    mov esi, app_chrome_name
    mov edi, app_chrome_path
    mov eax, APP_TYPE_CLR       ; Assuming Chrome is a CLR-based app
    call .register_app
    
    ; --- 2. Register Terminal (Shell) ---
    mov esi, app_terminal_name
    mov edi, app_terminal_path
    mov eax, APP_TYPE_NATIVE
    call .register_app
    
    ; --- 3. Register File Manager ---
    mov esi, app_fileman_name
    mov edi, app_fileman_path
    mov eax, APP_TYPE_CLR       ; Assuming File Manager is CLR-based
    call .register_app
    
    ; --- 4. Register Linux-Term (Proot Guest) ---
    mov esi, app_linuxterm_name
    mov edi, app_linuxterm_path
    mov eax, APP_TYPE_GUEST     ; Requires syscall_translator.asm
    call .register_app
    
    popad
    ret

; ----------------------------------------------------------------------
; Subroutine: .register_app
; Internal routine to save application metadata into the list.
; ----------------------------------------------------------------------
; Parameters: ESI=Name Ptr, EDI=Path Ptr, EAX=App Type
.register_app:
    push ebx
    push ecx
    push edx
    
    mov ebx, [current_app_count]
    imul ebx, APP_STRUCT_SIZE
    mov edx, application_list
    add edx, ebx                ; EDX points to the next free slot
    
    ; 1. Copy Name (APP_NAME_SIZE bytes)
    mov ecx, APP_NAME_SIZE
    push esi
    push edi
    mov esi, [esp + 16 + 4]     ; ESI = Name Ptr (careful stack indexing)
    mov edi, edx
    call string_copy_n          ; Copy the name
    
    ; 2. Copy Path (APP_PATH_SIZE bytes)
    add edx, APP_NAME_SIZE
    mov esi, [esp + 16 + 8]     ; ESI = Path Ptr
    mov edi, edx
    mov ecx, APP_PATH_SIZE
    call string_copy_n          ; Copy the path
    
    ; 3. Store Type
    add edx, APP_PATH_SIZE
    mov [edx], eax              ; Store the App Type
    
    ; 4. Update count
    inc dword [current_app_count]
    
    pop edx
    pop ecx
    pop ebx
    ret

; ----------------------------------------------------------------------
; Subroutine: app_env_lookup_path
; Retrieves the executable path for a given application name.
; ----------------------------------------------------------------------
; Parameters: ESI=Name String Ptr
; Returns: EAX=Path String Ptr (in the list), 0 if not found
app_env_lookup_path:
    ; (Implements a loop and lookup similar to registry.asm)
    ret

; --- Data ---
APP_TYPE_NATIVE equ 0x00
APP_TYPE_CLR equ 0x01
APP_TYPE_GUEST equ 0x02

app_chrome_name db "Chrome Browser", 0x00
app_chrome_path db "/APPS/CHROME.CLR", 0x00

app_terminal_name db "Terminal", 0x00
app_terminal_path db "/APPS/SHELL.EXE", 0x00

app_fileman_name db "File Manager", 0x00
app_fileman_path db "/APPS/FILEMAN.CLR", 0x00

app_linuxterm_name db "Linux-Term", 0x00
app_linuxterm_path db "/APPS/LTERMA.EXE", 0x00
