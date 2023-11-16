bits 64

; Définition des syscalls
%define SYS_write 1
%define SYS_close 3
%define SYS_socket 41
%define SYS_accept 43
%define SYS_bind 49
%define SYS_listen 50
%define SYS_exit 60

; Définition des fd
%define STDIN 0
%define STDOUT 1
%define STDERR 2

; Définition de constantes
%define AF_INET 2
%define SOCK_STREAM 1
%define sockaddr_in_len 16
%define backlog 5

section .data
	; hello msg
	hello_msg: db "Starting web server ...", 10
	hello_msg_len: equ $-hello_msg

	; error msg
	error_msg: db "Quitting web server with error ...", 10
	error_msg_len: equ $-error_msg

	; socket msg
	socket_msg: db "Socket ...", 10
	socket_msg_len: equ $-socket_msg

	; bind msg
	bind_msg: db "Bind ...", 10
	bind_msg_len: equ $-bind_msg

	; listen msg
	listen_msg: db "Listen ...", 10
	listen_msg_len: equ $-listen_msg

	; accept msg
	accept_msg: db "Accept ...", 10
	accept_msg_len: equ $-accept_msg

	; write msg
	write_msg: db "write ...", 10
	write_msg_len: equ $-write_msg

	; Web page
	web_page: db 	"HTTP/1.1 200 OK", 13, 10, \
					"Content-Length: 163", 13, 10, \
					"Content-Type: text/html", 13, 10, 13, 10, \
					"<h1>Hello, World !</h1>", \
					"<h2>from assembly.</h2>", \
					"<style>", \
					"*{text-align: center;background-color: #1e1e2e;color: #cdd6f4;}", \
					"h1{font-size: 10vw;}", \
					"h2{font-size: 5vw;}", \
					"</style>", \
					"Hello, World! from Assembly", 0
	web_page_len: equ $-web_page

	; Structure sockaddr_in
	;; sin_family_t --> __kernel_sa_family_t --> unsigned short --> 2 octets
	;; sin_port --> __be16 --> __u16 --> uint16_t --> 2 octets
	;; struct in_addr sin_addr --> uint32_t --> 4 octets
	struc sockaddr_in
		sin_family_t: resw 1
		in_port_t: resw 1
		sin_addr: resd 1
		fill: resq 1
	endstruc

	my_sockaddr_in istruc sockaddr_in
		at sin_family_t, dw AF_INET
		at in_port_t, dw 0hc61e
		at sin_addr, dd 0h0100007F ; 127.0.0.1
		at fill, dq 0b0
	iend
	my_sockaddr_in_len: equ $-my_sockaddr_in

	client_sockaddr_in istruc sockaddr_in
		at sin_family_t, dw 0d0
		at in_port_t, dw 0d0
		at sin_addr, dd 0d0 
		at fill, dq 0b0
	iend
	client_sockaddr_in_len: dq 0d16

section .bss
	server_sockfd: resq 1
	client_sockfd: resq 1

section .text
	global _start

_start:
	; Affichage du message de début
	mov rax, SYS_write
	mov rdi, STDOUT
	mov rsi, hello_msg
	mov rdx, hello_msg_len
	syscall

	; Création du socket
	mov rax, SYS_socket
	mov rdi, AF_INET
	mov rsi, SOCK_STREAM
	mov rdx, 0d0
	syscall

	; Sauvegarde de server_sockfd
	mov [server_sockfd], rax

	; Quitte si rax < 0
	cmp rax, 0d0
	jl exit_with_error

	; Affichage du message de socket
	mov rax, SYS_write
	mov rdi, STDOUT
	mov rsi, socket_msg
	mov rdx, socket_msg_len
	syscall

	; Bindons sur localhost:7878
	mov rax, SYS_bind
	mov rdi, [server_sockfd]
	mov rsi, my_sockaddr_in
	mov rdx, my_sockaddr_in_len
	syscall

	; Quitte si rax < 0
	cmp rax, 0d0
	jl exit_with_error

	; Affichage du message de bind
	mov rax, SYS_write
	mov rdi, STDOUT
	mov rsi, bind_msg
	mov rdx, bind_msg_len
	syscall

	; Attente d'une connection `man 2 listen`
	mov rax, SYS_listen
	mov rdi, [server_sockfd]
	mov rsi, backlog
	syscall

	; Quitte si rax < 0
	cmp rax, 0d0
	jl exit_with_error

	; Affichage du message de listen
	mov rax, SYS_write
	mov rdi, STDOUT
	mov rsi, listen_msg
	mov rdx, listen_msg_len
	syscall

next:
	; Accepter une request
	mov rax, SYS_accept
	mov rdi, [server_sockfd]
	mov rsi, client_sockaddr_in
	mov rdx, client_sockaddr_in_len
	syscall

	; Sauvegarder le nouveau sock fd
	mov [client_sockfd], rax

	; Quitte si rax < 0
	cmp rax, 0d0
	jl exit_with_error

	; Affichage du message de accept
	mov rax, SYS_write
	mov rdi, STDOUT
	mov rsi, accept_msg
	mov rdx, accept_msg_len
	syscall

	mov rax, SYS_write
	mov rdi, [client_sockfd]
	mov rsi, web_page
	mov rdx, web_page_len
	syscall

	mov rax, SYS_write
	mov rdi, STDOUT
	mov rsi, write_msg
	mov rdx, write_msg_len
	syscall

	; mov rax, SYS_close
	; mov rdi, server_sockfd
	; syscall

	; mov rax, SYS_close
	; mov rdi, client_sockfd
	; syscall

	jmp next

exit:
	mov rax, SYS_close
	mov rdi, [server_sockfd]
	syscall

	mov rax, SYS_close
	mov rdi, [client_sockfd]
	syscall

	mov rax, SYS_exit
	xor rdi, rdi
	syscall

exit_with_error:
	mov rax, SYS_close
	mov rdi, [server_sockfd]
	syscall

	mov rax, SYS_close
	mov rdi, [client_sockfd]
	syscall

	mov rax, SYS_write
	mov rdi, STDERR
	mov rsi, error_msg
	mov rdx, error_msg_len
	syscall 

	mov rax, SYS_exit
	xor rdi, rdi
	syscall