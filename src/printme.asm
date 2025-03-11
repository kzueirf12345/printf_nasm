section .data

MAX_REG_VAL     equ 0xFFFFFFFF
END_STR         equ 0x0
section .text

global printme

;;; =========================================FUNCS==================================================
;;; ---------------------------------------------
;;; Descript:   printme wrapper
;;; Entry:      rdi = address string  
;;; Exit:       rax = exit code
;;; Destroy: 	rcx, rdx, rsi, rdi
;;; ---------------------------------------------
printme:
;;; Prologue
    push rbp
    mov rbp, rsp

;;; push args in stack
    push r9 
    push r8 
    push rcx 
    push rdx 
    push rsi 
    push rdi

    call printme_trully

;;; Epilogue
.Exit:
    mov rsp, rbp
    pop rbp
ret

;;; ---------------------------------------------
;;; Descript:   print string with \0 in end on concole
;;; Entry:      STACK: string addr 
;;; Exit:       rax = exit code
;;; Destroy: 	rcx, rdx, rsi, rdi
;;; ---------------------------------------------
printme_trully:
    pop rax                                 ; save ret addr
    pop rsi                                 ; rsi - string addr
    push rax                                ; save ret addr

    mov rdx, 1                              ; count symbols for print
    mov rax, 0x1                            ; syscall print string
    mov rdi, 1                              ; descriptor - stdout

.HandleString:
    cmp byte [rsi], END_STR                 ; check end string
je .Exit

    syscall                                 ; print string

    inc rsi                                 ; next sym
jmp .HandleString

.Exit:
    xor rax, rax                              ; exit code
ret

;;; =========================================DATA===================================================
section .data

Vmsg     db "Hello, world!", 0xA, "kek", 0xA, END_STR
Vmsg_len  equ $ - Vmsg

section .bss