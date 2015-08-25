#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Rokas Kupstys
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

.intel_syntax noprefix

.global narch_getRegisters
.global _narch_getRegisters
narch_getRegisters:
_narch_getRegisters:
    mov   [rcx], rax
    mov   [rcx+0x08], rbx
    mov   [rcx+0x10], rcx
    mov   [rcx+0x18], rdx
    mov   [rcx+0x20], rsi
    mov   [rcx+0x28], rdi
    mov   [rcx+0x30], rbp
    mov   [rcx+0x38], rsp
    mov   rax, [rsp]
    mov   [rcx+0x40], rax     # rip
    mov   [rcx+0x48], r8
    mov   [rcx+0x50], r9
    mov   [rcx+0x58], r10
    mov   [rcx+0x60], r11
    mov   [rcx+0x68], r12
    mov   [rcx+0x70], r13
    mov   [rcx+0x78], r14
    mov   [rcx+0x80], r15
    ret

.global narch_setjmp
.global _narch_setjmp
narch_setjmp:
_narch_setjmp:
    # Based on code from musl libc Copyright © 2005-2014 Rich Felker, et al.
    mov   [rcx], rbx          # rcx is jmp_buf, move registers onto it
    mov   [rcx+0x08], rbp
    mov   [rcx+0x10], r12
    mov   [rcx+0x18], r13
    mov   [rcx+0x20], r14
    mov   [rcx+0x28], r15
    lea   rdx, [rsp+0x08]     # this is our rsp WITHOUT current ret addr
    mov   [rcx+0x30], rdx
    mov   rdx, [rsp]          # save return addr ptr for new rip
    mov   [rcx+0x38], rdx
    mov   [rcx+0x40], rsi
    mov   [rcx+0x48], rdi
    xor   rax, rax            # always return 0
    ret

.global narch_longjmp
.global _narch_longjmp
narch_longjmp:
_narch_longjmp:
    # Based on code from musl libc Copyright © 2005-2014 Rich Felker, et al.
    mov   rax, rdx            # val will be longjmp return
    test  rax, rax
    jnz   1f
    inc   rax                 # if val==0, val=1 per longjmp semantics
1:
    mov   rbx, [rcx]          # rax is the jmp_buf, restore regs from it
    mov   rbp, [rcx+0x08]
    mov   r12, [rcx+0x10]
    mov   r13, [rcx+0x18]
    mov   r14, [rcx+0x20]
    mov   r15, [rcx+0x28]
    mov   rsp, [rcx+0x30]     # this ends up being the stack pointer
    mov   rdx, [rcx+0x38]     # this is the instruction pointer
    jmp   rdx                 # goto saved address without altering rsp

.global narch_coroSwitchStack
.global _narch_coroSwitchStack
narch_coroSwitchStack:
_narch_coroSwitchStack:
    pop rax                   # return address
    mov rdx, rsp              # old rsp for saving
    mov rsp, rcx              # swap stack with one passed to func
    push rdx                  # store old stack pointer on newly switched stack
    sub rsp, 0x28             # stack alignment + shadow space
    jmp rax                   # return

.global narch_coroRestoreStack
.global _narch_coroRestoreStack
narch_coroRestoreStack:
_narch_coroRestoreStack:
    pop rax                   # return address
    add rsp, 0x28             # stack alignment + shadow space
    pop rsp                   # resture old stack pointer
    jmp rax                   # return
