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
#if defined(__MINGW32__) || defined(__MINGW64__)
.globl @narch_coroExecWithStack@8
.globl @narch_setjmp@4
.globl @narch_longjmp@8
#endif
.text


#if defined(__MINGW32__) || defined(__MINGW64__)
@narch_coroExecWithStack@8:
#endif
narch_coroExecWithStack:
  mov  %edx, %esp            # swap stack with one passed to func
  sub  $0x10, %esp           # 16-byte alignment
  and  $-0x10, %esp          #
  sub  $4, %esp              # Simulate misalignment caused by return addr
  jmp *%ecx


#if defined(__MINGW32__) || defined(__MINGW64__)
@narch_setjmp@4:
#endif
narch_setjmp:
    mov  %ebx, (%ecx)
    mov  %esi, 0x04(%ecx)
    mov  %edi, 0x08(%ecx)
    mov  %ebp, 0x0C(%ecx)
    lea  0x04(%esp), %eax
    mov  %eax, 0x10(%ecx)
    mov  (%esp), %eax
    mov  %eax, 0x14(%ecx)
    xor  %eax, %eax
    ret


#if defined(__MINGW32__) || defined(__MINGW64__)
@narch_longjmp@8:
#endif
narch_longjmp:
    mov  %edx, %eax
    test %eax, %eax
    jnz  narch_longjmp_1
    inc  %eax
narch_longjmp_1:
    mov  (%ecx), %ebx
    mov  0x04(%ecx), %esi
    mov  0x08(%ecx), %edi
    mov  0x0C(%ecx), %ebp
    mov  0x10(%ecx), %esp
    mov  0x14(%ecx), %edx
    jmp *%edx
