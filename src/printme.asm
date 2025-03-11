section .data

MAX_REG_VAL     equ 0xFFFFFFFF
END_STR         equ 0x0

;;; =========================================FUNCS==================================================
section .text

global printme

;;; ---------------------------------------------
;;; Descript:   printme wrapper
;;; Entry:      rdi = address string
;;;             next regs and stack - args
;;; Exit:       rax = exit code
;;; Destroy: 	rax
;;; ---------------------------------------------
printme:
;;; Prologue
    mov r10, rbp
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
    mov rbp, r10
ret

;;; ---------------------------------------------
;;; Descript:   print string with \0 in end on concole
;;; Entry:      STACK: string addr, args
;;; Exit:       rax = exit code
;;;             0 - success
;;;             1 - error % specifer
;;; Destroy: 	rax, rcx, rdx, rsi, rdi, r8, r9
;;; ---------------------------------------------
printme_trully:
    pop r8                                 ; save ret addr
    pop rsi                                 ; rsi - string addr

    mov rdx, 1                              ; count symbols for print
    mov rax, 0x1                            ; syscall print string
    mov rdi, 1                              ; descriptor - stdout

.HandleString:
    cmp byte [rsi], END_STR                 ; check end string
je .ExitSuccess

    cmp byte [rsi], '%'                     ; check to specifer
jne .NoSpecifer

    inc rsi                                 ; rsi - specifer symbol

;;; r9 - addr to handle cur specifer = ([rsi]-'a')*8 + *SpeciferTable
    xor r9, r9
    mov r9b, byte [rsi]
    sub r9, 'a'
    shl r9, 3
    add r9, .SpeciferTable
jmp [r9]

.SpeciferTable:
dq .SpeciferNothingPhone
dq .SpeciferNothingPhone
dq .SpeciferC

.NoSpecifer

    push rax                                ; save rax
    syscall                                 ; print sym
    cmp rax, rdx                            ; check syscall error
jne .SyscallError
    pop rax                                 ; save rax

    inc rsi                                 ; next sym
jmp .HandleString

.ExitSuccess
    xor rax, rax                            ; exit code
.Exit:
    push r8                                ; save ret addr
ret


.SpeciferC:
    mov r9, rsi                            ; save rsi

    mov rsi, rsp                            ; rsi - addr char for print
    push rax                                ; save rax
    syscall                                 ; print char
    cmp rax, rdx                            ; check syscall error
jne .SyscallError
    pop rax                                 ; save rax
    add rsp, 8                              ; next arg

    mov rsi, r9                            ; save rsi
    inc rsi                                 ; next symbol
jmp .HandleString

.SpeciferNothingPhone:
    mov rax, 1
jmp .Exit

.SyscallError:
    mov rax, 2
jmp .Exit