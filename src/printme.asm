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

    pop rcx                                 ; r9 - ret addr
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
    sub rcx, 'a'
    shl rcx, 3
    add rcx, .SpeciferTable
jmp [rcx]

.SpeciferTable:
dq .SpeciferNothingPhone
dq .SpeciferNothingPhone
dq .SpeciferC
dq .SpeciferD

.NoSpecifer:

    mov rdx, 1                              ; count symbols for print
    mov rdi, 1                              ; descriptor - stdout
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
    mov rdx, 1                              ; count symbols for print
    mov rdi, 1                              ; descriptor - stdout
    mov rax, 0x1                            ; syscall print string
    syscall                                 ; print char
    cmp rax, rdx                            ; check syscall error
jne .SyscallError

    add r8, 8                               ; next arg
    pop rsi                                 ; save rsi
    inc rsi                                 ; next symbol
jmp .HandleString

.SpeciferD:
    push rsi                                ; save rsi

    mov eax, [r8]                           ; eax - num for print
    mov r11d, 10                            ; r11d - base
    call print_int
    test rax, rax                           ; check error
jne .Exit

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

;;; ---------------------------------------------
;;; Descript:   print int
;;; Entry:      eax  = num
;;;             r11d = base
;;; Exit:       rax = exit code
;;;             rdx = string size
;;; Destroy: 	rcx, rdx, rsi, rdi, r11
;;; ---------------------------------------------
print_int:
    mov edi, eax                            ; edi - num

    xor rcx, rcx                            ; rcx - string size

;;; check to zero and negative
    test eax, eax
js .Negative
jne .Convertion
;;; push '0' in stack
    dec rsp
    mov byte [rsp], '0'
    inc rcx                                 ; ++size
jmp .Print

.Negative:
    neg eax                                 ; num = -num

.Convertion:
    xor edx, edx                            ; edx (upper part) = 0
    div r11d                                ; [eax, edx] = edx:eax / r11d
    add dl, '0'                             ; edx += "0"
;;; push dl (digit) in stack
    dec rsp
    mov byte [rsp], dl

    inc rcx                                 ; ++size
    test eax, eax
jne .Convertion

;;; check to negative (add '-')
    test edi, edi
jns .Print
;;; push '-' in stack
    dec rsp
    mov byte [rsp], '-'
    inc rcx                                 ; ++size

.Print:
    mov rdx, rcx                            ; rdx - size string
    mov rsi, rsp                            ; rsi - addr string for print
    mov rdi, 1
    mov rax, 0x1
    syscall                                 ; print num string
    cmp rdx, rax                            ; check syscall error
je .ExitSuccess
    mov rax, 2

.ExitSuccess:
    add rsp, rdx
    xor rax, rax
ret