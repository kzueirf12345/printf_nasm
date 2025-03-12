section .data

MAX_REG_VAL                 equ 0xFFFFFFFF
END_STR                     equ 0x0

STDOUT_DESCRIPTOR           equ 1

;;; syscall funcs
SYSCALL_NUM_PRINT_STRING    equ 0x1

;;; ERRORS
ERROR_INCORRECT_SPECIFER    equ 1
ERROR_SYSCALL               equ 2


HexTable                    db "0123456789ABCDEF"

;;; =========================================FUNCS==================================================
section .text

global printme

;;; ---------------------------------------------
;;; Descript:   printme wrapper
;;; Entry:      rdi = address string
;;;             next regs and stack - args
;;; Exit:       rax = exit code
;;; Destroy:    rcx, rdx, rsi, rdi, r8, r11
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

    pop rcx                                 ; rcx - ret addr
    add rsp, 5*8                            ; skip pushed args
    push rcx                                ; push ret addr
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
;;; Destroy: 	rcx, rdx, rsi, rdi, r11
;;; ---------------------------------------------
printme_trully:

.HandleString:
    cmp byte [rsi], END_STR                 ; check end string
je .ExitSuccess

    cmp byte [rsi], '%'                     ; check to specifer
jne .NoSpecifer

    inc rsi                                 ; rsi - specifer symbol

;;; rcx - addr to handle cur specifer = ([rsi]-'a')*8 + *SpeciferTable
    xor rcx, rcx
    mov cl, byte [rsi]
    shl rcx, 3
    add rcx, .SpeciferTable
jmp [rcx]

.SpeciferTable:
dq ('%')        DUP (.SpeciferNothingPhone)
dq .NoSpecifer                             ; handle %%
dq ('b'-'%'-1)  DUP (.SpeciferNothingPhone)
dq .SpeciferB
dq .SpeciferC
dq .SpeciferD
dq ('o'-'d'-1)  DUP (.SpeciferNothingPhone)
dq .SpeciferO
dq ('x'-'o'-1)  DUP (.SpeciferNothingPhone)
dq .SpeciferX
dq (256-'x'-1)  DUP (.SpeciferNothingPhone)

.NoSpecifer:

    mov rdx, 1                              ; rdx - count symbols for print
    mov rdi, STDOUT_DESCRIPTOR
    mov rax, SYSCALL_NUM_PRINT_STRING
    syscall                                 ; print sym
    cmp rax, rdx                            ; check syscall error
jne .SyscallError

    inc rsi                                 ; next sym
jmp .HandleString

.ExitSuccess:
    xor rax, rax                            ; NO ERROR
.Exit:
ret


.SpeciferC:
    push rsi                                ; save rsi

    mov rsi, r8                             ; rsi - addr char for print
    mov rdx, 1                              ; rdx - count symbols for print
    mov rdi, STDOUT_DESCRIPTOR
    mov rax, SYSCALL_NUM_PRINT_STRING
    syscall                                 ; print char
    cmp rax, rdx                            ; check syscall error
jne .SyscallError

    add r8, 8                               ; next arg
    pop rsi                                 ; save rsi
    inc rsi                                 ; next symbol
jmp .HandleString


.SpeciferB:
    mov r11, 2                              ; r11 - base
    call specifer_num
    test rax, rax                           ; check error
jne .Exit
jmp .HandleString
    
.SpeciferD:
    mov r11, 10                             ; r11 - base
    call specifer_num
    test rax, rax                           ; check error
jne .Exit
jmp .HandleString

.SpeciferO:
    mov r11, 8                              ; r11 - base
    call specifer_num
    test rax, rax                           ; check error
jne .Exit
jmp .HandleString

.SpeciferX:
    mov r11, 16                             ; r11 - base
    call specifer_num
    test rax, rax                           ; check error
jne .Exit
jmp .HandleString


.SpeciferNothingPhone:
    mov rax, ERROR_INCORRECT_SPECIFER
jmp .Exit

.SyscallError:
    mov rax, ERROR_SYSCALL
jmp .Exit

;;; ---------------------------------------------
;;; Descript:   print num
;;; Entry:      r11 = base
;;;             r8  = addr print num
;;;             rsi = cur addr in format string
;;; Exit:       rax = exit code
;;;             rdx = string size
;;;             r8  = next arg
;;;             rsi = next symbol
;;; Destroy: 	rcx, rdx, rdi, r11
;;; ---------------------------------------------
specifer_num:
    push rsi                                ; save rsi

    mov rax, [r8]                           ; rax - num for print
    call print_num

    add r8, 8                               ; next arg
    pop rsi                                 ; save rsi
    inc rsi                                 ; next symbol
ret

;;; ---------------------------------------------
;;; Descript:   print num
;;; Entry:      rax  = num
;;;             r11 = base
;;; Exit:       rax = exit code
;;;             rdx = string size
;;; Destroy: 	rcx, rdx, rsi, rdi, r11
;;; ---------------------------------------------
print_num:
    mov rdi, rax                            ; rdi - num

    xor rcx, rcx                            ; rcx - string size

;;; check to zero and negative
    test rax, rax
js .Negative
jne .Convertion
;;; push '0' in stack
    dec rsp
    mov byte [rsp], '0'
    inc rcx                                 ; ++size
jmp .Print

.Negative:
    neg rax                                 ; num = -num

.Convertion:
    xor rdx, rdx                            ; rdx = 0 (in particular edx)
    div r11                                 ; [rax, rdx] = rdx:rax / r11
    mov dl, byte [HexTable + rdx]           ; dl = HexTable[dl]
;;; push dl (digit) in stack
    dec rsp
    mov byte [rsp], dl

    inc rcx                                 ; ++size
    test rax, rax
jne .Convertion

;;; check to negative (add '-')
    test rdi, rdi
jns .Print
;;; push '-' in stack
    dec rsp
    mov byte [rsp], '-'
    inc rcx                                 ; ++size

.Print:
    mov rdx, rcx                            ; rdx - size string
    mov rsi, rsp                            ; rsi - addr string for print
    mov rdi, STDOUT_DESCRIPTOR
    mov rax, SYSCALL_NUM_PRINT_STRING
    syscall                                 ; print num string
    cmp rdx, rax                            ; check syscall error
je .ExitSuccess
    mov rax, ERROR_SYSCALL

.ExitSuccess:
    add rsp, rdx                            ; clean stack (rdx - size string)
    xor rax, rax                            ; NO ERROR
ret