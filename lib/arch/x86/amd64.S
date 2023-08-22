#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Rokas Kupstys
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
# Partially based on code from musl libc Copyright © 2005-2014 Rich Felker, et al.

.globl narch_coroExecWithStack
.globl narch_setjmp
.globl narch_longjmp
.text


# SysV ABI - first argument is rdi.
# MS ABI   - first argument is rcx.
#if defined(__MINGW32__) || defined(__MINGW64__)
  #define REG_ARG1 rcx
  #define REG_ARG2 rdx
#else
  #define REG_ARG1 rdi
  #define REG_ARG2 rsi
#endif


narch_coroExecWithStack:
  mov  %REG_ARG2, %rsp        # swap stack with one passed to func
  sub  $0x30, %rsp            # shadow space (for ms ABI) 0x20 + 0x10 for possible misalignment
  and  $-0x10, %rsp           # 16-byte stack alignment
  call *%REG_ARG1


narch_setjmp:
  add   $0x10, %REG_ARG1      # 16-byte alignment
  and   $-0x10, %REG_ARG1
  mov   %rbx, 0x00(%REG_ARG1) # jmp_buf, move registers onto it
  mov   %rbp, 0x08(%REG_ARG1)
  mov   %r12, 0x10(%REG_ARG1)
  mov   %r13, 0x18(%REG_ARG1)
  mov   %r14, 0x20(%REG_ARG1)
  mov   %r15, 0x28(%REG_ARG1)
  lea   0x08(%rsp), %rdx      # this is our rsp WITHOUT current ret addr
  mov   %rdx, 0x30(%REG_ARG1)
  mov   (%rsp), %rdx          # save return addr ptr for new rip
  mov   %rdx, 0x38(%REG_ARG1)
  mov   %rsi, 0x40(%REG_ARG1)
  mov   %rdi, 0x48(%REG_ARG1)
#if defined(__MINGW32__) || defined(__MINGW64__)
  movaps %xmm6,  0x50(%REG_ARG1)
  movaps %xmm7,  0x60(%REG_ARG1)
  movaps %xmm8,  0x70(%REG_ARG1)
  movaps %xmm9,  0x80(%REG_ARG1)
  movaps %xmm10, 0x90(%REG_ARG1)
  movaps %xmm11, 0xA0(%REG_ARG1)
  movaps %xmm12, 0xB0(%REG_ARG1)
  movaps %xmm13, 0xC0(%REG_ARG1)
  movaps %xmm14, 0xD0(%REG_ARG1)
  movaps %xmm15, 0xE0(%REG_ARG1)
#endif
  xor   %rax, %rax            # always return 0
  ret


narch_longjmp:
  add   $0x10, %REG_ARG1      # 16-byte alignment
  and   $-0x10, %REG_ARG1     #
  mov   %REG_ARG2, %rax       # val will be longjmp return
  test  %rax, %rax
  jnz   narch_longjmp_1
  inc   %rax                  # if val==0, val=1 per longjmp semantics
narch_longjmp_1:
  mov   0x00(%REG_ARG1), %rbx # jmp_buf, restore regs from it
  mov   0x08(%REG_ARG1), %rbp
  mov   0x10(%REG_ARG1), %r12
  mov   0x18(%REG_ARG1), %r13
  mov   0x20(%REG_ARG1), %r14
  mov   0x28(%REG_ARG1), %r15
  mov   0x30(%REG_ARG1), %rsp # this ends up being the stack pointer
  mov   0x38(%REG_ARG1), %rdx # this is the instruction pointer
  mov   0x40(%REG_ARG1), %rsi
  mov   0x48(%REG_ARG1), %rdi
#if defined(__MINGW32__) || defined(__MINGW64__)
  movaps 0x50(%REG_ARG1), %xmm6
  movaps 0x60(%REG_ARG1), %xmm7
  movaps 0x70(%REG_ARG1), %xmm8
  movaps 0x80(%REG_ARG1), %xmm9
  movaps 0x90(%REG_ARG1), %xmm10
  movaps 0xA0(%REG_ARG1), %xmm11
  movaps 0xB0(%REG_ARG1), %xmm12
  movaps 0xC0(%REG_ARG1), %xmm13
  movaps 0xD0(%REG_ARG1), %xmm14
  movaps 0xE0(%REG_ARG1), %xmm15
#endif
  jmp  *%rdx                  # goto saved address without altering rsp
