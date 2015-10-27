;
;
;            Nim's Runtime Library
;        (c) Copyright 2015 Rokas Kupstys
;
;    See the file "copying.txt", included in this
;    distribution, for details about the copyright.
;

format MS64 COFF

section ".text" executable align 16
public narch_getRegisters
public narch_setjmp
public narch_longjmp
public narch_coroSwitchStack
public narch_coroRestoreStack


narch_getRegisters:
    mov   [rcx], rax
    mov   [rcx+8], rbx
    mov   [rcx+10h], rcx
    mov   [rcx+18h], rdx
    mov   [rcx+20h], rsi
    mov   [rcx+28h], rdi
    mov   [rcx+30h], rbp
    mov   [rcx+38h], rsp
    mov   rax, [rsp]
    mov   [rcx+40h], rax      ; rip
    mov   [rcx+48h], r8
    mov   [rcx+50h], r9
    mov   [rcx+58h], r10
    mov   [rcx+60h], r11
    mov   [rcx+68h], r12
    mov   [rcx+70h], r13
    mov   [rcx+78h], r14
    mov   [rcx+80h], r15
    ret


narch_setjmp:
    ; Based on code from musl libc Copyright © 2005-2014 Rich Felker, et al.
    mov   [rcx], rbx          ; rcx is jmp_buf, move registers onto it
    mov   [rcx+8], rbp
    mov   [rcx+10h], r12
    mov   [rcx+18h], r13
    mov   [rcx+20h], r14
    mov   [rcx+28h], r15
    lea   rdx, [rsp+8]        ; this is our rsp WITHOUT current ret addr
    mov   [rcx+30h], rdx
    mov   rdx, [rsp]          ; save return addr ptr for new rip
    mov   [rcx+38h], rdx
    mov   [rcx+40h], rsi
    mov   [rcx+48h], rdi
    xor   rax, rax            ; always return 0
    ret

narch_longjmp:
    ; Based on code from musl libc Copyright © 2005-2014 Rich Felker, et al.
    mov   rax, rdx            ; val will be longjmp return
    test  rax, rax
    jnz   @F
    inc   rax                 ; if val==0, val=1 per longjmp semantics
@@:
    mov   rbx, [rcx]          ; rax is the jmp_buf, restore regs from it
    mov   rbp, [rcx+8]
    mov   r12, [rcx+10h]
    mov   r13, [rcx+18h]
    mov   r14, [rcx+20h]
    mov   r15, [rcx+28h]
    mov   rsp, [rcx+30h]      ; this ends up being the stack pointer
    mov   rdx, [rcx+38h]      ; this is the instruction pointer
    jmp   rdx                 ; goto saved address without altering rsp


narch_coroSwitchStack:
    pop rax                   ; return address
    mov rdx, rsp              ; old rsp for saving
    mov rsp, rcx              ; swap stack with one passed to func
    push rdx                  ; store old stack pointer on newly switched stack
    sub rsp, 28h              ; stack alignment + shadow space
    jmp rax                   ; return


narch_coroRestoreStack:
    pop rax                   ; return address
    add rsp, 28h              ; stack alignment + shadow space
    pop rsp                   ; resture old stack pointer
    jmp rax                   ; return
