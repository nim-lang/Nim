;
;
;            Nim's Runtime Library
;        (c) Copyright 2015 Rokas Kupstys
;
;    See the file "copying.txt", included in this
;    distribution, for details about the copyright.
;

format ELF64

section ".text" executable align 16
public narch_getRegisters
public narch_setjmp
public narch_longjmp
public narch_coroSwitchStack
public narch_coroRestoreStack


narch_getRegisters:
    mov   [rdi], rax
    mov   [rdi+8], rbx
    mov   [rdi+10h], rcx
    mov   [rdi+18h], rdx
    mov   [rdi+20h], rsi
    mov   [rdi+28h], rdi
    mov   [rdi+30h], rbp
    mov   [rdi+38h], rsp
    mov   rax, [rsp]
    mov   [rdi+40h], rax      ; rip
    mov   [rdi+48h], r8
    mov   [rdi+50h], r9
    mov   [rdi+58h], r10
    mov   [rdi+60h], r11
    mov   [rdi+68h], r12
    mov   [rdi+70h], r13
    mov   [rdi+78h], r14
    mov   [rdi+80h], r15
    ret


narch_setjmp:
    ; Based on code from musl libc Copyright © 2005-2014 Rich Felker, et al.
    mov   [rdi], rbx          ; rdi is jmp_buf, move registers onto it
    mov   [rdi+8], rbp
    mov   [rdi+10h], r12
    mov   [rdi+18h], r13
    mov   [rdi+20h], r14
    mov   [rdi+28h], r15
    lea   rdx, [rsp+8]        ; this is our rsp WITHOUT current ret addr
    mov   [rdi+30h], rdx
    mov   rdx, [rsp]          ; save return addr ptr for new rip
    mov   [rdi+38h], rdx
    xor   rax, rax            ; always return 0
    ret


narch_longjmp:
    ; Based on code from musl libc Copyright © 2005-2014 Rich Felker, et al.
    mov   rax, rsi            ; val will be longjmp return
    test  rax, rax
    jnz   @F
    inc   rax                 ; if val==0, val=1 per longjmp semantics
@@:
    mov   rbx, [rdi]          ; rdi is the jmp_buf, restore regs from it
    mov   rbp, [rdi+8]
    mov   r12, [rdi+10h]
    mov   r13, [rdi+18h]
    mov   r14, [rdi+20h]
    mov   r15, [rdi+28h]
    mov   rsp, [rdi+30h]      ; this ends up being the stack pointer
    mov   rdx, [rdi+38h]      ; this is the instruction pointer
    jmp   rdx                 ; goto saved address without altering rsp


narch_coroSwitchStack:
    pop rsi                   ; return address
    mov rdx, rsp              ; old rsp for saving
    mov rsp, rdi              ; swap stack with one passed to func
    push rdx                  ; store old stack pointer on newly switched stack
    sub rsp, 8h               ; stack alignment
    jmp rsi                   ; return


narch_coroRestoreStack:
	pop rsi                   ; return address
	add rsp, 8h               ; stack alignment
	pop rsp                   ; resture old stack pointer
	jmp rsi                   ; return
