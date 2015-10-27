;
;
;            Nim's Runtime Library
;        (c) Copyright 2015 Rokas Kupstys
;
;    See the file "copying.txt", included in this
;    distribution, for details about the copyright.
;

section ".text" executable
public narch_getRegisters
public @narch_getRegisters@4
public narch_setjmp
public @narch_setjmp@4
public narch_longjmp
public @narch_longjmp@8
public narch_coroSwitchStack
public @narch_coroSwitchStack@4
public narch_coroRestoreStack
public @narch_coroRestoreStack@0

@narch_getRegisters@4:
narch_getRegisters:
    mov   [ecx], eax
    mov   [ecx+4], ebx
    mov   [ecx+8], ecx
    mov   [ecx+0Ch], ebp
    mov   [ecx+10h], esp
    mov   [ecx+14h], edi
    mov   [ecx+18h], esi
    ret


@narch_setjmp@4:
narch_setjmp:
    ; Based on code from musl libc Copyright © 2005-2014 Rich Felker, et al.
    mov  [ecx], ebx
    mov  [ecx+4], esi
    mov  [ecx+8], edi
    mov  [ecx+0Ch], ebp
    lea  eax, [esp+4]
    mov  [ecx+10h], eax
    mov  eax, [esp]
    mov  [ecx+14h], eax
    xor  eax, eax
    ret


@narch_longjmp@8:
narch_longjmp:
    ; Based on code from musl libc Copyright © 2005-2014 Rich Felker, et al.
    mov  eax, edx
    test eax, eax
    jnz  @F
    inc  eax
@@:
    mov  ebx, [ecx]
    mov  esi, [ecx+4]
    mov  edi, [ecx+8]
    mov  ebp, [ecx+0Ch]
    mov  esp, [ecx+10h]
    mov  edx, [ecx+14h]
    jmp  edx


@narch_coroSwitchStack@4:
narch_coroSwitchStack:
    pop eax                   ; return address
    mov edx, esp              ; old esp for saving
    mov esp, ecx              ; swap stack with one passed to func
    push edx                  ; store old stack pointer on newly switched stack
    jmp eax                   ; return


@narch_coroRestoreStack@0:
narch_coroRestoreStack:
    pop eax                   ; return address
    pop esp                   ; resture old stack pointer
    jmp eax                   ; return
