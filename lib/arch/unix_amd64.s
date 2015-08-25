#
#
#           Nim's Runtime Library
#       (c) Copyright 2015 Rokas Kupstys
#
#   See the file "copying.txt", included in this
#   distribution, for details about the copyright.
#

.intel_syntax noprefix

.global narch_getRegisters
.global _narch_getRegisters
narch_getRegisters:
_narch_getRegisters:
    mov   [rdi], rax
    mov   [rdi+0x08], rbx
    mov   [rdi+0x10], rcx
    mov   [rdi+0x18], rdx
    mov   [rdi+0x20], rsi
    mov   [rdi+0x28], rdi
    mov   [rdi+0x30], rbp
    mov   [rdi+0x38], rsp
    mov   rax, [rsp]
    mov   [rdi+0x40], rax     # rip
    mov   [rdi+0x48], r8
    mov   [rdi+0x50], r9
    mov   [rdi+0x58], r10
    mov   [rdi+0x60], r11
    mov   [rdi+0x68], r12
    mov   [rdi+0x70], r13
    mov   [rdi+0x78], r14
    mov   [rdi+0x80], r15
    ret

.global narch_setjmp
.global _narch_setjmp
narch_setjmp:
_narch_setjmp:
    # Based on code from musl libc Copyright © 2005-2014 Rich Felker, et al.
    mov   [rdi], rbx          # rdi is jmp_buf, move registers onto it
    mov   [rdi+0x08], rbp
    mov   [rdi+0x10], r12
    mov   [rdi+0x18], r13
    mov   [rdi+0x20], r14
    mov   [rdi+0x28], r15
    lea   rdx, [rsp+0x08]     # this is our rsp WITHOUT current ret addr
    mov   [rdi+0x30], rdx
    mov   rdx, [rsp]          # save return addr ptr for new rip
    mov   [rdi+0x38], rdx
    xor   rax, rax            # always return 0
    ret

.global narch_longjmp
.global _narch_longjmp
narch_longjmp:
_narch_longjmp:
    # Based on code from musl libc Copyright © 2005-2014 Rich Felker, et al.
    mov   rax, rsi            # val will be longjmp return
    test  rax, rax
    jnz   1f
    inc   rax                 # if val==0, val=1 per longjmp semantics
1:
    mov   rbx, [rdi]          # rdi is the jmp_buf, restore regs from it
    mov   rbp, [rdi+0x08]
    mov   r12, [rdi+0x10]
    mov   r13, [rdi+0x18]
    mov   r14, [rdi+0x20]
    mov   r15, [rdi+0x28]
    mov   rsp, [rdi+0x30]     # this ends up being the stack pointer
    mov   rdx, [rdi+0x38]     # this is the instruction pointer
    jmp   rdx                 # goto saved address without altering rsp

.global narch_coroSwitchStack
.global _narch_coroSwitchStack
narch_coroSwitchStack:
_narch_coroSwitchStack:
    pop rsi                   # return address
    mov rdx, rsp              # old rsp for saving
    mov rsp, rdi              # swap stack with one passed to func
    push rdx                  # store old stack pointer on newly switched stack
    sub rsp, 0x8              # stack alignment
    jmp rsi                   # return

.global narch_coroRestoreStack
.global _narch_coroRestoreStack
narch_coroRestoreStack:
_narch_coroRestoreStack:
    pop rsi                   # return address
    add rsp, 0x8              # stack alignment
    pop rsp                   # resture old stack pointer
    jmp rsi                   # return
