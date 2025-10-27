; ----------------------------------------------------------------------
; File: vnc_protocol.asm
; Purpose: Implements the TigerVNC (RFB - Remote Frame Buffer) protocol
; ----------------------------------------------------------------------

bits 16

; --- Constants for VNC Protocol ---
VNC_PORT        equ 5900
RFB_MAJOR       equ 0x03    ; RFB Protocol Version 3.8
RFB_MINOR       equ 0x08
MESSAGE_TYPE_FBU equ 0     ; FramebufferUpdate message type
MESSAGE_TYPE_KEY equ 4     ; KeyEvent message type

; --- Data Section ---
vnc_version_msg  db "RFB 003.008", 0x0A ; VNC Version Message (3.8)
client_init_msg  db 1                   ; ClientInit: 1 = Shared Desktop

; Global VNC state variables
vnc_state db 0             ; 0=Version, 1=Security, 2=Init, 3=Running
vnc_fb_width dw 0          ; Framebuffer width received from server
vnc_fb_height dw 0         ; Framebuffer height received from server

; --- External Subroutines (from network.asm, lib.asm) ---
; extern nic_init, network_send, network_receive, tcp_connect, tcp_disconnect
; extern graphics_init, draw_rect

; ----------------------------------------------------------------------
; Subroutine: vnc_start
; Establishes the connection and starts the VNC loop.
; ----------------------------------------------------------------------
vnc_start:
    pusha
    
    ; 1. Initialize Network and TCP Connection
    ; call nic_init
    ; call tcp_connect ; (Connect to VNC_PORT, requires server IP)
    
    ; 2. VNC Protocol Handshake
    call vnc_version_exchange
    call vnc_security_exchange
    call vnc_client_init
    
    ; 3. Enter Main VNC Loop
    call vnc_main_loop
    
    popa
    ret

; ----------------------------------------------------------------------
; Subroutine: vnc_version_exchange
; Sends PieOS's VNC version and receives the server's version.
; ----------------------------------------------------------------------
vnc_version_exchange:
    ; Send: "RFB 003.008\n"
    ; call network_send (vnc_version_msg, 12 bytes)
    
    ; Receive: Server's version string
    ; call network_receive (and compare)
    ret

; ----------------------------------------------------------------------
; Subroutine: vnc_client_init
; Sends client info and receives server init message (screen size, etc.)
; ----------------------------------------------------------------------
vnc_client_init:
    ; Send: ClientInit message (1 byte: Shared Flag)
    ; call network_send (client_init_msg, 1 byte)
    
    ; Receive: ServerInit message (Screen size, pixel format, Desktop Name)
    ; (Store received width/height into vnc_fb_width/height)
    ; (The kernel's graphics must already be initialized to a compatible size)
    ret

; ----------------------------------------------------------------------
; Subroutine: vnc_main_loop
; Main loop for receiving and processing server messages.
; ----------------------------------------------------------------------
vnc_main_loop:
.loop_start:
    ; Send an explicit request for a Framebuffer Update
    call vnc_request_update 
    
    ; Wait for and receive the next server message
    ; call network_receive
    
    ; Process the received message based on its type byte
    ; If type == MESSAGE_TYPE_FBU: call vnc_process_update
    ; If type == other: handle other messages (Color Map, Bell, etc.)
    
    jmp .loop_start

; ----------------------------------------------------------------------
; Subroutine: vnc_process_update
; Handles incoming FramebufferUpdate messages and draws to the screen.
; ----------------------------------------------------------------------
vnc_process_update:
    ; 1. Read the number of rectangles (rect_count)
    ; 2. Loop rect_count times:
    ;   a. Read X, Y, Width, Height of the rectangle.
    ;   b. Read Encoding Type (e.g., Raw, Hextile).
    ;   c. Read and process the pixel data based on the encoding.
    ;   d. Use graphics.asm's draw_rect to put the pixels on screen.
    ret
