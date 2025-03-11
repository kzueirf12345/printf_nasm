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

    mov rdx, 1                              ; count symbols for print
    mov rax, 0x1                            ; syscall print string
    mov rdi, 1                              ; descriptor - stdout

.HandleString:
    cmp byte [rsi], END_STR
je .Exit

    syscall                                 ; print string

    inc rsi
jmp .HandleString

.Exit:
ret

;;; =========================================DATA===================================================
section .data

Vmsg     db "Hello, world!", 0xA, "kek", 0xA, END_STR
Vmsg_len  equ $ - Vmsg

section .bss