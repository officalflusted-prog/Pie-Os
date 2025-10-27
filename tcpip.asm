; ----------------------------------------------------------------------
; File: tcpip.asm
; Purpose: Native 32-bit TCP/IP Stack and Socket Interface for PieOS
; ----------------------------------------------------------------------

bits 32

; --- Protocol Constants ---
ETH_TYPE_IP  equ 0x0800  ; Ethernet Type for IP
ETH_TYPE_ARP equ 0x0806  ; Ethernet Type for ARP
IP_PROTO_TCP equ 0x06    ; IP Protocol for TCP
IP_PROTO_UDP equ 0x11    ; IP Protocol for UDP

; --- Global Network Data ---
local_ip_addr dd 0xC0A8010A ; 192.168.1.10 (Hardcoded for now)
local_mac_addr times 6 db 0 ; Loaded by the NIC driver
arp_cache_table times 16 * 10 db 0 ; Table for IP-to-MAC resolution (16 entries * 10 bytes)

; --- Socket Data Structure (Simplified) ---
; Max 4 sockets, 16 bytes per socket
; [0-3]: Socket State (Closed, Listening, Established, etc.)
; [4-7]: Remote IP Address
; [8-9]: Remote Port
; [10-11]: Local Port
socket_table times 4 * 16 db 0

; --- External Subroutines ---
; extern nic_send_frame, nic_receive_frame (Placeholder for the NIC driver)
; extern vmem_alloc_pages, vmem_free_pages (for packet buffers)

; ----------------------------------------------------------------------
; Subroutine: tcpip_init
; Initializes the stack and the underlying NIC hardware.
; ----------------------------------------------------------------------
tcpip_init:
    pushad
    
    ; 1. Initialize the NIC (e.g., call nic_driver_init)
    ; 2. Request local MAC address from the NIC and store it
    ; 3. Perform initial ARP broadcast to announce presence on the network
    
    popad
    ret

; ----------------------------------------------------------------------
; Subroutine: tcpip_input_handler
; The primary function called by the NIC driver on packet reception.
; ----------------------------------------------------------------------
; Parameters:
;   ESI: Pointer to the raw Ethernet frame buffer
tcpip_input_handler:
    pushad
    
    ; 1. Check Ethernet Header (Source/Dest MAC, EtherType)
    movzx ebx, word [esi + 0xC] ; Get EtherType
    
    cmp ebx, ETH_TYPE_ARP
    je .handle_arp

    cmp ebx, ETH_TYPE_IP
    je .handle_ip
    
    ; Discard unknown packet types
    jmp .done

.handle_arp:
    ; Process ARP request/reply, update arp_cache_table
    ; If it's a request for our IP, send an ARP reply
    jmp .done

.handle_ip:
    ; 2. Check IP Header (Version, Checksum, Protocol)
    mov bl, [esi + 0x17]        ; Get IP Protocol byte (TCP, UDP, ICMP)
    
    cmp bl, IP_PROTO_TCP
    je .handle_tcp

    cmp bl, IP_PROTO_UDP
    je .handle_udp
    
    ; Discard unknown IP protocols
    jmp .done

.handle_tcp:
    ; 3. Process TCP Header (Ports, Flags, Sequence/ACK numbers)
    ; Use the port numbers to look up the correct entry in socket_table
    ; If new connection (SYN): call tcp_accept
    ; If data: Buffer the data and signal the application waiting on that socket
    jmp .done

.handle_udp:
    ; Process UDP data (simpler than TCP)
    jmp .done

; ----------------------------------------------------------------------
; Subroutine: socket_send
; The high-level API for applications to send data.
; ----------------------------------------------------------------------
; Parameters:
;   EAX: Socket ID (Index into socket_table)
;   EBX: Pointer to data buffer
;   ECX: Size of data
socket_send:
    ; 1. Look up remote IP/Port in socket_table
    ; 2. Look up remote MAC in arp_cache_table (if missing, send ARP request first)
    ; 3. Construct TCP/IP/Ethernet headers
    ; 4. call nic_send_frame
    ret
