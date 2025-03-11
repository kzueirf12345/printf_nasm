section .data

MAX_REG_VAL     equ 0xFFFFFFFF
END_STR         equ 0x0
section .text

global _start

;;; =========================================MAIN===================================================

_start: 
    mov rsi, Vmsg                           ; string addr for print
    call printf
    
    mov rax, 0x3C      ; exit64 (rdi)
    xor rdi, rdi
    syscall

;;; =========================================FUNCS==================================================
;;; ---------------------------------------------
;;; Descript:   print string with \0 in end on concole
;;; Entry:      rsi = address string  
;;; Exit:       None
;;; Destroy: 	rax, rcx, rdx, rsi, rdi
;;; ---------------------------------------------
printf:

;;; calculate string size
    mov rdi, rsi                            ; rdi - string address for find
    mov rcx, MAX_REG_VAL                    ; rdx - counter string size
    mov al, END_STR                         ; al - end string symbol (\0)
    repne scasb

;;; rdx - string size = MAX_REG_VAL - rcx
    mov rdx, MAX_REG_VAL
    sub rdx, rcx

    mov rax, 0x1                            ; syscall print string
    mov rdi, 1                              ; descriptor - stdout
    syscall
ret

;;; =========================================DATA===================================================
section .data

Vmsg     db "Hello, world!", 0xa, END_STR
Vmsg_len  equ $ - Vmsg

section .bss