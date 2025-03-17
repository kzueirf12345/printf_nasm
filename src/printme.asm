section .data
;;; //TODO double

MAX_REG_VAL                 equ 0xFFFFFFFF
END_STR                     equ 0x0
SYS_CNT_BITS                equ 64

STDOUT_DESCRIPTOR           equ 1

;;; syscall funcs
SYSCALL_NUM_PRINT_STRING    equ 0x1

;;; ERRORS
ERROR_INCORRECT_SPECIFER    equ 1
ERROR_SYSCALL               equ 2

;;; Variables

HexTable                    db "0123456789ABCDEF"

BUFFER_SIZE                 equ 64
Buffer:                     db (BUFFER_SIZE) DUP (0)
BUFFER_END                  equ $
;;; r10 - cur addr after last buffer elem

CntPrintedSymbols:           dq 0


;;; =========================================FUNCS==================================================
section .text

global printme

;;; ---------------------------------------------
;;; Descript:   printme wrapper
;;; Entry:      rdi = address string
;;;             next regs and stack - args
;;; Exit:       rax = exit code
;;; Destroy:    rcx, rdx, rsi, rdi, r8, r10, r11
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
    call PrintmeTrully

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
;;;             r8 = addr after last arg
;;; Destroy: 	rcx, rdx, rsi, rdi, r10, r11
;;; ---------------------------------------------
PrintmeTrully:
    mov r10, Buffer                         ; r10 - cur addr after last buffer elem (begin)

.HandleString:
    cmp byte [rsi], END_STR                 ; check end string
je .ExitSuccess

    cmp byte [rsi], '%'                     ; check to specifer
jne .NoSpecifer

    inc rsi                                 ; rsi - specifer symbol

;;; rcx - addr to handle cur specifer = ([rsi]-'%')*8 + &SpeciferTable
    xor rcx, rcx
    mov cl, byte [rsi]
    cmp rcx, 'x'
jg .SpeciferNothingPhone
    sub rcx, '%'
    shl rcx, 3
    add rcx, .SpeciferTable

jmp [rcx]

.SpeciferTable:
dq .NoSpecifer                             ; handle %%
dq ('b'-'%'-1)  DUP (.SpeciferNothingPhone)
dq .SpeciferB
dq .SpeciferC
dq .SpeciferD
dq ('n'-'d'-1)  DUP (.SpeciferNothingPhone)
dq .SpeciferN 
dq .SpeciferO
dq ('s'-'o'-1)  DUP (.SpeciferNothingPhone)
dq .SpeciferS
dq ('x'-'s'-1)  DUP (.SpeciferNothingPhone)
dq .SpeciferX

.NoSpecifer:

    mov rdx, 1                              ; rdx - count symbols for print
    call PrintData
    test rax, rax                           ; check error
jne .Exit

    ; inc rsi                                 ; next sym
jmp .HandleString

.ExitSuccess:
    call PrintBuffer
.Exit:
    mov qword [CntPrintedSymbols], 0
ret


.SpeciferC:
    push rsi                                ; save rsi

    mov rsi, r8                             ; rsi - addr char for print
    mov rdx, 1                              ; rdx - count symbols for print
    call PrintData
    test rax, rax                           ; check error
jne .Exit

    add r8, 8                               ; next arg
    pop rsi                                 ; save rsi
    inc rsi                                 ; next symbol
jmp .HandleString

.SpeciferS:
    push rsi                                ; save rsi

    mov rdi, [r8]                           ; rdi - addr string for print
    call HandleString
    test rax, rax                           ; check error
jne .Exit

    add r8, 8                               ; next arg
    pop rsi                                 ; save rsi
    inc rsi                                 ; next symbol
jmp .HandleString

.SpeciferN:
;;; mov count printed symbols in args addr
    mov rcx, qword [CntPrintedSymbols]
    mov r11, [r8]
    mov [r11], rcx

    add r8, 8                               ; next arg
    inc rsi                                 ; next symbol
jmp .HandleString

.SpeciferB:
    mov r11b, 1                             ; r11b - log2(base)
    call SpeciferNum2
    test rax, rax                           ; check error
jne .Exit
jmp .HandleString
    
.SpeciferD:
    push rsi                                ; save rsi

    mov r11, 10                             ; r11 - base
    mov rax, [r8]                           ; rax - num for print
    call HandleNum
    test rax, rax                           ; check error
jne .Exit

    add r8, 8                               ; next arg
    pop rsi                                 ; save rsi
    inc rsi                                 ; next symbol
jmp .HandleString

.SpeciferO:
    mov r11b, 3                             ; r11b - log2(base)
    call SpeciferNum2
    test rax, rax                           ; check error
jne .Exit
jmp .HandleString

.SpeciferX:
    mov r11b, 4                             ; r11b - log2(base)
    call SpeciferNum2
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
;;; Descript:   push symbols in buffer (print if overflow)
;;; Entry:      rsi = start symbols arr addr
;;;             rdx = count symbols
;;;             r10 = addr after last buffer elem
;;; Exit:       rax = exit code
;;;             r10 = addr after last buffer elem
;;;             rsi = old_rsi + rdx
;;; Destroy: 	rcx, rsi, rdi, r11
;;; ---------------------------------------------
PrintData:
    mov rax, r10                            ; rax - addr after last buffer elem
;;; r10+rdx >? BUFFER_END
    add r10, rdx
    cmp r10, BUFFER_END
jg .NoUseBuffer      

    mov rdi, rax                            ; rdi - dest addr in buffer
    mov rcx, rdx                            ; rcx - count moveable syms
    rep movsb                               ; mov rcx syms from rsi to buffer

    mov r10, rdi                            ; r10 - new addr after last buffer elem
jmp .ExitSuccess

.NoUseBuffer:

    cmp rax, Buffer                         ; check to empty buffer
je .EmptyBuffer

    push rdx                                ; save rdx
    push rsi                                ; save rsi

    mov r10, rax                            ; r10 - addr after last buffer elem
    call PrintBuffer
    test rax, rax                           ; check error
jne .Exit

    pop rsi                                 ; save rsi - addr from print
    pop rdx                                 ; save rdx - count symbols for print
.EmptyBuffer:
    mov rax, SYSCALL_NUM_PRINT_STRING
    mov rdi, STDOUT_DESCRIPTOR
    syscall                                 ; print rdx symbols in rsi
    add qword [CntPrintedSymbols], rax      ; update CntPrintedSymbols
    cmp rdx, rax                            ; check syscall error
jne .SyscallError

    add rsi, rdx                            ; update rsi
.ExitSuccess:
    xor rax, rax                            ; NO ERROR
.Exit:
ret


.SyscallError:
    mov rax, ERROR_SYSCALL
jmp .Exit

;;; ---------------------------------------------
;;; Descript:   print buffer and clear him
;;; Entry:      r10 = addr after last buffer elem
;;; Exit:       rax = exit code
;;;             r10 = buffer start addr
;;; Destroy: 	rcx, rdx, rsi, rdi, r11
;;; ---------------------------------------------
PrintBuffer:
    mov rdx, r10                            ; rdx=r10-&Buffer - count symbols in buffer
    sub rdx, Buffer

    mov rsi, Buffer                         ; rsi - buffer addr
    mov rax, SYSCALL_NUM_PRINT_STRING
    mov rdi, STDOUT_DESCRIPTOR
    syscall                                 ; print symbols in buffer
    add qword [CntPrintedSymbols], rax      ; update CntPrintedSymbols
    cmp rdx, rax                            ; check syscall error
jne .SyscallError

    mov r10, Buffer                         ; r10 - new addr after last buffer elem (begin)

.ExitSuccess:
    xor rax, rax
.Exit:
ret

.SyscallError:
    mov rax, ERROR_SYSCALL
jmp .Exit


;;; ---------------------------------------------
;;; Descript:   print num
;;; Entry:      r11b = log2(base)
;;;             r8  = addr print num
;;;             rsi = cur addr in format string
;;; Exit:       rax = exit code
;;;             rdx = string size
;;;             r8  = next arg
;;;             rsi = next symbol
;;;             r10 = addr after last buffer elem
;;; Destroy: 	rcx, rdx, rdi, r9, r11
;;; ---------------------------------------------
SpeciferNum2:
    push rsi                                ; save rsi

    push r11
    call PrintBuffer
    test rax, rax
jne .Exit
    pop r11

    mov rax, [r8]                           ; rax - num for print
    call HandleNum2

    add r8, 8                               ; next arg
    pop rsi                                 ; save rsi
    inc rsi                                 ; next symbol

.ExitSuccess:
    xor rax, rax                            ; NO ERROR
.Exit:
ret

;;; ---------------------------------------------
;;; Descript:   print num
;;; Entry:      rax  = num
;;;             r11 = base
;;; Exit:       rax = exit code
;;;             rdx = string size
;;;             r10 = addr after last buffer elem
;;; Destroy: 	rcx, rdx, rsi, rdi, r11
;;; ---------------------------------------------
HandleNum:
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
    call PrintData
    add rsp, rdx                            ; clean stack (rdx - size string)
    test rax, rax                           ; check error
jne .Exit

.ExitSuccess:
    xor rax, rax                            ; NO ERROR
.Exit:
ret

;;; ---------------------------------------------
;;; Descript:   print num
;;; Entry:      rax  = num
;;;             r11b = log2(base)
;;;             r10 = addr after last buffer elem
;;; Exit:       rax = exit code
;;;             r10 = addr after last buffer elem
;;; Destroy: 	rcx, rdx, rsi, rdi, r9, r11
;;; ---------------------------------------------
HandleNum2:

;;; check to zero
    test rax, rax
je .Zero

    mov r9, rax                             ; r9 - duplicate num
    xor dl, dl                              ; dl - offset counter

.SkipZeros:
    mov rax, r9                             ; rax - original num

;;; rax << dl - remove left bytes
    mov cl, dl
    shl rax, cl

;;; rax >> (64 - r11b) - remove right bytes
    mov cl, 64
    sub cl, r11b
    shr rax, cl

    add dl, r11b                            ; next offset

    test rax, rax                           ; check to non zero
je .SkipZeros

    sub dl, r11b                            ; back to first non zero digit offset

.Convertion
    mov rax, r9                             ; rax - original num

;;; rax << dl - remove left bytes
    mov cl, dl
    shl rax, cl

;;; rax >> (64 - r11b) - remove right bytes
    mov cl, 64
    sub cl, r11b
    shr rax, cl

    mov al, byte [HexTable + rax]           ; al = HexTable[al]

    mov byte [r10], al
    inc r10

    add dl, r11b                            ; next offset
    cmp dl, 64                              ; check to max offset 64
jl .Convertion

.ExitSuccess:
    xor rax, rax                            ; NO ERROR
.Exit:
ret

.Zero:
    push rax                                ; save num

    dec rsp                                 ; push '0' (1 byte)
    mov byte [rsp], '0'
    mov rsi, rsp                            ; rsi - addr '0'
    mov rdx, 1                              ; rdx - count printed sym
    call PrintData
    inc rsp                                 ; remove '-' from stack
    test rax, rax                           ; check error
jne .Exit

    pop rax                                 ; save num
jmp .ExitSuccess

;;; ---------------------------------------------
;;; Descript:   print string (0 in end)
;;; Entry:      rdi = string addr
;;;             r10 = addr after last buffer elem
;;; Exit:       rax = exit code
;;;             r10 = addr after last buffer elem
;;; Destroy: 	rcx, rdx, rsi, rdi, r11
;;; ---------------------------------------------
HandleString:
    push rdi                                ; save begin string addr
;;; count string size
    xor al, al                              ; al - end string symbol (0)
    mov rcx, MAX_REG_VAL                    ; max string size
    repne scasb

    pop rsi                                 ; rsi - begin string addr
;;; rdx = rdi-rsi-1 - string size
    mov rdx, rdi
    sub rdx, rsi
    dec rdx
    call PrintData
    test rax, rax                           ; check error
jne .Exit

.ExitSuccess:
    xor rax, rax                            ; NO ERROR
.Exit:
ret