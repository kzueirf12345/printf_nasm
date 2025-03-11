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
;;; Destroy:    rcx, rdx, rsi, rdi, r8, r9
;;; ---------------------------------------------
printme:
    pop rax                                 ; rax - ret addr
;;; push args in stack
    push r9 
    push r8 
    push rcx 
    push rdx 
    push rsi 
    
    mov r8, rsp                             ; r8 - addr start args

    push rax                                ; push ret addr

    mov rsi, rdi                            ; rsi - addr format string 
    call printme_trully

    pop r9                                  ; r9 - ret addr
    add rsp, 5*8                            ; skip pushed args
    push r9                                 ; push ret addr
ret

;;; ---------------------------------------------
;;; Descript:   print format string with \0 in end on concole
;;;             Specifers: %c - char
;;; Entry:      r8 = addr start args
;;;             rsi = format string
;;; Exit:       rax = exit code
;;;             0 - success
;;;             1 - error % specifer
;;;             2 - syscall error
;;;             r8 = addr after last arg
;;; Destroy: 	rcx, rdx, rsi, rdi, r9
;;; ---------------------------------------------
printme_trully:
    mov rdx, 1                              ; count symbols for print
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

.NoSpecifer:

    mov rax, 0x1                            ; syscall print string
    syscall                                 ; print sym
    cmp rax, rdx                            ; check syscall error
jne .SyscallError

    inc rsi                                 ; next sym
jmp .HandleString

.ExitSuccess:
    xor rax, rax                            ; exit code
.Exit:
ret


.SpeciferC:
    push rsi                                ; save rsi

    mov rsi, r8                             ; rsi - addr char for print
    mov rax, 0x1                            ; syscall print string
    syscall                                 ; print char
    cmp rax, rdx                            ; check syscall error
jne .SyscallError

    add r8, 8                               ; next arg
    pop rsi                                 ; save rsi
    inc rsi                                 ; next symbol
jmp .HandleString

.SpeciferNothingPhone:
    mov rax, 1
jmp .Exit

.SyscallError:
    mov rax, 2
jmp .Exit