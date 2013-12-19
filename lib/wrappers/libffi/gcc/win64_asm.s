# 1 "gcc\\win64_asm.asm"
# 1 "<command-line>"
# 1 "gcc\\win64_asm.asm"

# 1 "common/fficonfig.h" 1
# 3 "gcc\\win64_asm.asm" 2
# 1 "common/ffi.h" 1
# 63 "common/ffi.h"
# 1 "common/ffitarget.h" 1
# 64 "common/ffi.h" 2
# 4 "gcc\\win64_asm.asm" 2
# 244 "gcc\\win64_asm.asm"
.text

.extern ffi_closure_win64_inner
# 255 "gcc\\win64_asm.asm"
 .balign 16
        .globl ffi_closure_win64
ffi_closure_win64:

 test $1,%r11
 jne .Lfirst_is_float
 mov %rcx, 8(%rsp)
 jmp .Lsecond
.Lfirst_is_float:
 movlpd %xmm0, 8(%rsp)

.Lsecond:
 test $2, %r11
 jne .Lsecond_is_float
 mov %rdx, 16(%rsp)
 jmp .Lthird
.Lsecond_is_float:
 movlpd %xmm1, 16(%rsp)

.Lthird:
 test $4, %r11
 jne .Lthird_is_float
 mov %r8,24(%rsp)
 jmp .Lfourth
.Lthird_is_float:
 movlpd %xmm2, 24(%rsp)

.Lfourth:
 test $8, %r11
 jne .Lfourth_is_float
 mov %r9, 32(%rsp)
 jmp .Ldone
.Lfourth_is_float:
 movlpd %xmm3, 32(%rsp)

.Ldone:

 sub $40, %rsp

 mov %rax, %rcx
 mov %rsp, %rdx
 add $48, %rdx
 mov $SYMBOL_NAME(ffi_closure_win64_inner), %rax
 callq *%rax
 add $40, %rsp
 movq %rax, %xmm0

 retq
.ffi_closure_win64_end:

 .balign 16
        .globl ffi_call_win64
ffi_call_win64:

 mov %r9,32(%rsp)
 mov %r8,24(%rsp)
 mov %rdx,16(%rsp)
 mov %rcx,8(%rsp)

 push %rbp

 sub $48,%rsp

 lea 32(%rsp),%rbp


 mov 48(%rbp),%eax
 add $15, %rax
 and $-16, %rax
 cmpq $0x1000, %rax
 jb Lch_done
Lch_probe:
 subq $0x1000,%rsp
 orl $0x0, (%rsp)
 subq $0x1000,%rax
 cmpq $0x1000,%rax
 ja Lch_probe
Lch_done:
 subq %rax, %rsp
 orl $0x0, (%rsp)
 lea 32(%rsp), %rax
 mov %rax, 0(%rbp)

 mov 40(%rbp), %rdx
 mov 0(%rbp), %rcx
 callq *32(%rbp)

 mov 0(%rbp), %rsp

 movlpd 24(%rsp), %xmm3
 movd %xmm3, %r9

 movlpd 16(%rsp), %xmm2
 movd %xmm2, %r8

 movlpd 8(%rsp), %xmm1
 movd %xmm1, %rdx

 movlpd (%rsp), %xmm0
 movd %xmm0, %rcx

 callq *72(%rbp)
.Lret_struct4b:
  cmpl $FFI_TYPE_SMALL_STRUCT_4B, 56(%rbp)
  jne .Lret_struct2b

 mov 64(%rbp), %rcx
 mov %eax, (%rcx)
 jmp .Lret_void

.Lret_struct2b:
 cmpl $FFI_TYPE_SMALL_STRUCT_2B, 56(%rbp)
 jne .Lret_struct1b

 mov 64(%rbp), %rcx
 mov %ax, (%rcx)
 jmp .Lret_void

.Lret_struct1b:
 cmpl $FFI_TYPE_SMALL_STRUCT_1B, 56(%rbp)
 jne .Lret_uint8

 mov 64(%rbp), %rcx
 mov %al, (%rcx)
 jmp .Lret_void

.Lret_uint8:
 cmpl $FFI_TYPE_UINT8, 56(%rbp)
 jne .Lret_sint8

        mov 64(%rbp), %rcx
        movzbq %al, %rax
 movq %rax, (%rcx)
 jmp .Lret_void

.Lret_sint8:
 cmpl $FFI_TYPE_SINT8, 56(%rbp)
 jne .Lret_uint16

        mov 64(%rbp), %rcx
        movsbq %al, %rax
 movq %rax, (%rcx)
 jmp .Lret_void

.Lret_uint16:
 cmpl $FFI_TYPE_UINT16, 56(%rbp)
 jne .Lret_sint16

        mov 64(%rbp), %rcx
        movzwq %ax, %rax
 movq %rax, (%rcx)
 jmp .Lret_void

.Lret_sint16:
 cmpl $FFI_TYPE_SINT16, 56(%rbp)
 jne .Lret_uint32

        mov 64(%rbp), %rcx
        movswq %ax, %rax
 movq %rax, (%rcx)
 jmp .Lret_void

.Lret_uint32:
 cmpl $9, 56(%rbp)
 jne .Lret_sint32

        mov 64(%rbp), %rcx
        movl %eax, %eax
 movq %rax, (%rcx)
 jmp .Lret_void

.Lret_sint32:
  cmpl $10, 56(%rbp)
  jne .Lret_float

 mov 64(%rbp), %rcx
 cltq
 movq %rax, (%rcx)
 jmp .Lret_void

.Lret_float:
  cmpl $2, 56(%rbp)
  jne .Lret_double

  mov 64(%rbp), %rax
  movss %xmm0, (%rax)
  jmp .Lret_void

.Lret_double:
  cmpl $3, 56(%rbp)
  jne .Lret_sint64

  mov 64(%rbp), %rax
  movlpd %xmm0, (%rax)
  jmp .Lret_void

.Lret_sint64:
   cmpl $12, 56(%rbp)
   jne .Lret_void

  mov 64(%rbp), %rcx
  mov %rax, (%rcx)
  jmp .Lret_void

.Lret_void:
 xor %rax, %rax

 lea 16(%rbp), %rsp
 pop %rbp
 retq
.ffi_call_win64_end:
