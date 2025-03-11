section .text

global _start

_start: 
    mov rax, 0x01      ; write64 (rdi, rsi, rdx) ... r10, r8, r9
    mov rdi, 1         ; stdout
    mov rsi, Msg
    mov rdx, MsgLen    ; strlen (Msg)
    syscall
    
    mov rax, 0x3C      ; exit64 (rdi)
    xor rdi, rdi
    syscall

section .data

Msg:    db "Hello, world!", 0xa
MsgLen  equ $ - Msg

section .bss