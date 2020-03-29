SYS_EXIT        equ 60
SYS_READ        equ 0
SYS_WRITE       equ 1
MIN_CHAR        equ 49 
MAX_CHAR        equ 90
MAX_ARG_LENGTH  equ 42
BUFF_SIZE       equ 4096

global _start

section .bss

Lperm: resb 8                   ; Address of L permutation on stack
Rperm: resb 8                   ; Address of R permutation on stack
Tperm: resb 8                   ; Address of T permutation on stack
Linv:  resb MAX_ARG_LENGTH      ; Inversion of L permutation
Rinv:  resb MAX_ARG_LENGTH      ; Inversion of R permutation
buff:  resb 4097                ; Buffer for input-output
Lbegin: resb 1
Rbegin: resb 1


section .text

process_single_arg:                ; Sparsuj i zinvertuj jeden argument. rsi - source, rdi - target, r8 - ile liter ma byc
    xor     rcx, rcx
check_chars_loop:
    cmp     rcx, r8                 ; całe słowo wczytane, teraz musi być 0
    jl      check_single_char
    cmp     BYTE[rsi + rcx], 0           ; NULL terminator, następny argument
    jne     fail                   ; zbyt długie słowo
    ret
check_single_char:
    movzx   rax, BYTE[rsi + rcx]
    cmp     al, MIN_CHAR            ; czy w przedziale
    jl      fail
    cmp     al, MAX_CHAR
    jg      fail
    test    rdi, rdi                ; czy trzeba liczyć permutacje
    jz      next_char               ; jesli nie, to nastepna literka
    lea     rbx, [rdi + rax - MIN_CHAR] ; zaladuj adres na docelowej permutacji
    cmp     BYTE[rbx], 0
    jne     fail
    mov     [rbx], eax
next_char:
    inc     rcx                    ; licznik++
    jmp     check_chars_loop

encode_buffer:
    ret

_start:
    cmp     QWORD[rsp], 5          ; sprawdz czy dobra liczba argumentow
    jne     fail                   ; niepoprawna liczba argumentow -> wyjdz z niezerowym
    mov     r8, MAX_ARG_LENGTH
    lea     rbp, [rsp + 16]         ; adres args[1]
    mov     rsi, [rbp]
    mov     [Lperm], rsi             ; zapisz adres permutacji L
    mov     rdi, Linv
    call    process_single_arg
    add     rbp, 8
    mov     rsi, [rbp]
    mov     [Rperm], rsi             ; zapisz adres permutacji R
    mov     rdi, Rinv
    call    process_single_arg
    add     rbp, 8
    mov     rsi, [rbp]
    xor     rdi, rdi               ; wyczysc rdi, bo nie potrzebujemy inwersji T
    call    process_single_arg
    xor     rcx, rcx                ; licznik
check_T_permutation:                ; iterujemy sie po T i patrzymy czy poprawne zlozenie
    cmp     rcx, MAX_ARG_LENGTH
    je      check_key
    xor     rax, rax
    mov     al, BYTE[rsi + rcx]     ; na al jest literka
    lea     r8, [rsi + rax - MIN_CHAR] ; zaladuj na r8 adres literki w permutacji
    cmp     al, BYTE[r8]
    je      fail                    ; punkt staly
    mov     rdx, rcx                ; powinien byc wyzerowany
    add     rdx, MIN_CHAR
    cmp     dl, BYTE[rsi + rax - MIN_CHAR]
    jne     fail                    ; nie ma dwuelementowego cyklu
    inc     rcx
    jmp     check_T_permutation
check_key:
    add     rbp, 8
    mov     rsi, [rbp]
    xor     rdi, rdi
    mov     r8, 2                   ; ostatni argument ma tylko dwie literki
    call    process_single_arg
    movzx   rax, BYTE[rsi]
    mov     [Lbegin], al
    inc     rsi
    mov     al, BYTE[rsi]
    mov     [Rbegin], al
read_input:
    xor     eax, eax
    xor     edi, edi
    mov     rsi, buff
    mov     edx, BUFF_SIZE
    syscall
    mov     r12, rax
    mov     rsi, buff
    mov     BYTE[buff + r12], 0
    mov     rdi, 0
    mov     r8, r12
    call    process_single_arg
    call    encode_buffer
    mov     eax, 1
    xor     edi, edi
    mov     rsi, buff
    mov     rdx, r12
    syscall
    cmp     r12, BUFF_SIZE
    jge     read_input
    xor     rdi, rdi               ; wyczysc edi, exit z 0
    jmp     exit
fail:
    mov     edi, 1                 ; exit z codem 1
exit:
    mov     rax, SYS_EXIT
    syscall