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
    mov   [ecx], eax
    mov   [ecx+0x04], ebx
    mov   [ecx+0x08], ecx
    mov   [ecx+0x0C], ebp
    mov   [ecx+0x10], esp
    mov   [ecx+0x14], edi
    mov   [ecx+0x18], esi
    ret

.global narch_setjmp
.global _narch_setjmp
narch_setjmp:
_narch_setjmp:
    # Based on code from musl libc Copyright © 2005-2014 Rich Felker, et al.
    mov  [ecx], ebx
    mov  [ecx+0x04], esi
    mov  [ecx+0x08], edi
    mov  [ecx+0x0C], ebp
    lea  eax, [esp+0x04]
    mov  [ecx+0x10], eax
    mov  eax, [esp]
    mov  [ecx+0x14], eax
    xor  eax, eax
    ret

.global narch_longjmp
.global _narch_longjmp
narch_longjmp:
_narch_longjmp:
    # Based on code from musl libc Copyright © 2005-2014 Rich Felker, et al.
    mov  eax, edx
    test eax, eax
    jnz  1f
    inc  eax
1:
    mov  ebx, [ecx]
    mov  esi, [ecx+0x04]
    mov  edi, [ecx+0x08]
    mov  ebp, [ecx+0x0C]
    mov  esp, [ecx+0x10]
    mov  edx, [ecx+0x14]
    jmp  edx

.global narch_coroSwitchStack
.global _narch_coroSwitchStack
narch_coroSwitchStack:
_narch_coroSwitchStack:
    pop eax                   # return address
    mov edx, esp              # old esp for saving
    mov esp, ecx              # swap stack with one passed to func
    push edx                  # store old stack pointer on newly switched stack
    jmp eax                   # return

.global narch_coroRestoreStack
.global _narch_coroRestoreStack
narch_coroRestoreStack:
_narch_coroRestoreStack:
    pop eax                   # return address
    pop esp                   # resture old stack pointer
    jmp eax                   # return
