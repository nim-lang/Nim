# 1 "gcc\\win32_asm.asm"
# 1 "<command-line>"
# 1 "gcc\\win32_asm.asm"
# 33 "gcc\\win32_asm.asm"
# 1 "common/fficonfig.h" 1
# 34 "gcc\\win32_asm.asm" 2
# 1 "common/ffi.h" 1
# 63 "common/ffi.h"
# 1 "common/ffitarget.h" 1
# 64 "common/ffi.h" 2
# 35 "gcc\\win32_asm.asm" 2


 .text


        .balign 16
 .globl _ffi_call_win32

 .def _ffi_call_win32; .scl 2; .type 32; .endef

_ffi_call_win32:
.LFB1:
        pushl %ebp
.LCFI0:
        movl %esp,%ebp
.LCFI1:

        movl 20(%ebp),%ecx
        subl %ecx,%esp

        movl %esp,%eax


        pushl 12(%ebp)
        pushl %eax
        call *8(%ebp)


        addl $8,%esp


 cmpl $3, 16(%ebp)
 jz .do_thiscall
 cmpl $4, 16(%ebp)
 jnz .do_fncall
 movl (%esp), %ecx
 movl 4(%esp), %edx
 addl $8, %esp
 jmp .do_fncall
.do_thiscall:
 movl (%esp), %ecx
 addl $4, %esp

.do_fncall:




        call *32(%ebp)




        movl 24(%ebp),%ecx


        cmpl $0,28(%ebp)
        jne 0f



        cmpl $2,%ecx
        jne .Lnoretval
        fstp %st(0)

        jmp .Lepilogue

0:
 call 1f

.Lstore_table:
 .long .Lnoretval
 .long .Lretint
 .long .Lretfloat
 .long .Lretdouble
 .long .Lretlongdouble
 .long .Lretuint8
 .long .Lretsint8
 .long .Lretuint16
 .long .Lretsint16
 .long .Lretint
 .long .Lretint
 .long .Lretint64
 .long .Lretint64
 .long .Lretstruct
 .long .Lretint
 .long .Lretstruct1b
 .long .Lretstruct2b
 .long .Lretstruct4b
 .long .Lretstruct
1:
 add %ecx, %ecx
 add %ecx, %ecx
 add (%esp),%ecx
 add $4, %esp
 jmp *(%ecx)


.Lretsint8:
 movsbl %al, %eax
 jmp .Lretint

.Lretsint16:
 movswl %ax, %eax
 jmp .Lretint

.Lretuint8:
 movzbl %al, %eax
 jmp .Lretint

.Lretuint16:
 movzwl %ax, %eax
 jmp .Lretint

.Lretint:

        movl 28(%ebp),%ecx
        movl %eax,0(%ecx)
        jmp .Lepilogue

.Lretfloat:

        movl 28(%ebp),%ecx
        fstps (%ecx)
        jmp .Lepilogue

.Lretdouble:

        movl 28(%ebp),%ecx
        fstpl (%ecx)
        jmp .Lepilogue

.Lretlongdouble:

        movl 28(%ebp),%ecx
        fstpt (%ecx)
        jmp .Lepilogue

.Lretint64:

        movl 28(%ebp),%ecx
        movl %eax,0(%ecx)
        movl %edx,4(%ecx)
 jmp .Lepilogue

.Lretstruct1b:

        movl 28(%ebp),%ecx
        movb %al,0(%ecx)
        jmp .Lepilogue

.Lretstruct2b:

        movl 28(%ebp),%ecx
        movw %ax,0(%ecx)
        jmp .Lepilogue

.Lretstruct4b:

        movl 28(%ebp),%ecx
        movl %eax,0(%ecx)
        jmp .Lepilogue

.Lretstruct:


.Lnoretval:
.Lepilogue:
        movl %ebp,%esp
        popl %ebp
        ret
.ffi_call_win32_end:
        .balign 16
 .globl _ffi_closure_THISCALL

 .def _ffi_closure_THISCALL; .scl 2; .type 32; .endef

_ffi_closure_THISCALL:
 pushl %ebp
 movl %esp, %ebp
 subl $40, %esp
 leal -24(%ebp), %edx
 movl %edx, -12(%ebp)
 leal 12(%ebp), %edx
 jmp .stub
.LFE1:


        .balign 16
 .globl _ffi_closure_SYSV

 .def _ffi_closure_SYSV; .scl 2; .type 32; .endef

_ffi_closure_SYSV:
.LFB3:
 pushl %ebp
.LCFI4:
 movl %esp, %ebp
.LCFI5:
 subl $40, %esp
 leal -24(%ebp), %edx
 movl %edx, -12(%ebp)
 leal 8(%ebp), %edx
.stub:
 movl %edx, 4(%esp)
 leal -12(%ebp), %edx
 movl %edx, (%esp)
 call _ffi_closure_SYSV_inner
 movl -12(%ebp), %ecx

0:
 call 1f

.Lcls_store_table:
 .long .Lcls_noretval
 .long .Lcls_retint
 .long .Lcls_retfloat
 .long .Lcls_retdouble
 .long .Lcls_retldouble
 .long .Lcls_retuint8
 .long .Lcls_retsint8
 .long .Lcls_retuint16
 .long .Lcls_retsint16
 .long .Lcls_retint
 .long .Lcls_retint
 .long .Lcls_retllong
 .long .Lcls_retllong
 .long .Lcls_retstruct
 .long .Lcls_retint
 .long .Lcls_retstruct1
 .long .Lcls_retstruct2
 .long .Lcls_retstruct4
 .long .Lcls_retmsstruct

1:
 add %eax, %eax
 add %eax, %eax
 add (%esp),%eax
 add $4, %esp
 jmp *(%eax)


.Lcls_retsint8:
 movsbl (%ecx), %eax
 jmp .Lcls_epilogue

.Lcls_retsint16:
 movswl (%ecx), %eax
 jmp .Lcls_epilogue

.Lcls_retuint8:
 movzbl (%ecx), %eax
 jmp .Lcls_epilogue

.Lcls_retuint16:
 movzwl (%ecx), %eax
 jmp .Lcls_epilogue

.Lcls_retint:
 movl (%ecx), %eax
 jmp .Lcls_epilogue

.Lcls_retfloat:
 flds (%ecx)
 jmp .Lcls_epilogue

.Lcls_retdouble:
 fldl (%ecx)
 jmp .Lcls_epilogue

.Lcls_retldouble:
 fldt (%ecx)
 jmp .Lcls_epilogue

.Lcls_retllong:
 movl (%ecx), %eax
 movl 4(%ecx), %edx
 jmp .Lcls_epilogue

.Lcls_retstruct1:
 movsbl (%ecx), %eax
 jmp .Lcls_epilogue

.Lcls_retstruct2:
 movswl (%ecx), %eax
 jmp .Lcls_epilogue

.Lcls_retstruct4:
 movl (%ecx), %eax
 jmp .Lcls_epilogue

.Lcls_retstruct:

 movl %ebp, %esp
 popl %ebp
 ret $0x4

.Lcls_retmsstruct:

 mov %ecx, %eax

 jmp .Lcls_epilogue

.Lcls_noretval:
.Lcls_epilogue:
 movl %ebp, %esp
 popl %ebp
 ret
.ffi_closure_SYSV_end:
.LFE3:







        .balign 16
 .globl _ffi_closure_raw_THISCALL

 .def _ffi_closure_raw_THISCALL; .scl 2; .type 32; .endef

_ffi_closure_raw_THISCALL:
 pushl %ebp
 movl %esp, %ebp
 pushl %esi
 subl $36, %esp
 movl ((52 + 3) & ~3)(%eax), %esi
 movl ((((52 + 3) & ~3) + 4) + 4)(%eax), %edx
 movl %edx, 12(%esp)
 leal 12(%ebp), %edx
 jmp .stubraw

        .balign 16
 .globl _ffi_closure_raw_SYSV

 .def _ffi_closure_raw_SYSV; .scl 2; .type 32; .endef

_ffi_closure_raw_SYSV:
.LFB4:
 pushl %ebp
.LCFI6:
 movl %esp, %ebp
.LCFI7:
 pushl %esi
.LCFI8:
 subl $36, %esp
 movl ((52 + 3) & ~3)(%eax), %esi
 movl ((((52 + 3) & ~3) + 4) + 4)(%eax), %edx
 movl %edx, 12(%esp)
 leal 8(%ebp), %edx
.stubraw:
 movl %edx, 8(%esp)
 leal -24(%ebp), %edx
 movl %edx, 4(%esp)
 movl %esi, (%esp)
 call *(((52 + 3) & ~3) + 4)(%eax)
 movl 20(%esi), %eax
0:
 call 1f

.Lrcls_store_table:
 .long .Lrcls_noretval
 .long .Lrcls_retint
 .long .Lrcls_retfloat
 .long .Lrcls_retdouble
 .long .Lrcls_retldouble
 .long .Lrcls_retuint8
 .long .Lrcls_retsint8
 .long .Lrcls_retuint16
 .long .Lrcls_retsint16
 .long .Lrcls_retint
 .long .Lrcls_retint
 .long .Lrcls_retllong
 .long .Lrcls_retllong
 .long .Lrcls_retstruct
 .long .Lrcls_retint
 .long .Lrcls_retstruct1
 .long .Lrcls_retstruct2
 .long .Lrcls_retstruct4
 .long .Lrcls_retstruct
1:
 add %eax, %eax
 add %eax, %eax
 add (%esp),%eax
 add $4, %esp
 jmp *(%eax)


.Lrcls_retsint8:
 movsbl -24(%ebp), %eax
 jmp .Lrcls_epilogue

.Lrcls_retsint16:
 movswl -24(%ebp), %eax
 jmp .Lrcls_epilogue

.Lrcls_retuint8:
 movzbl -24(%ebp), %eax
 jmp .Lrcls_epilogue

.Lrcls_retuint16:
 movzwl -24(%ebp), %eax
 jmp .Lrcls_epilogue

.Lrcls_retint:
 movl -24(%ebp), %eax
 jmp .Lrcls_epilogue

.Lrcls_retfloat:
 flds -24(%ebp)
 jmp .Lrcls_epilogue

.Lrcls_retdouble:
 fldl -24(%ebp)
 jmp .Lrcls_epilogue

.Lrcls_retldouble:
 fldt -24(%ebp)
 jmp .Lrcls_epilogue

.Lrcls_retllong:
 movl -24(%ebp), %eax
 movl -20(%ebp), %edx
 jmp .Lrcls_epilogue

.Lrcls_retstruct1:
 movsbl -24(%ebp), %eax
 jmp .Lrcls_epilogue

.Lrcls_retstruct2:
 movswl -24(%ebp), %eax
 jmp .Lrcls_epilogue

.Lrcls_retstruct4:
 movl -24(%ebp), %eax
 jmp .Lrcls_epilogue

.Lrcls_retstruct:


.Lrcls_noretval:
.Lrcls_epilogue:
 addl $36, %esp
 popl %esi
 popl %ebp
 ret
.ffi_closure_raw_SYSV_end:
.LFE4:




 .balign 16
 .globl _ffi_closure_STDCALL

 .def _ffi_closure_STDCALL; .scl 2; .type 32; .endef

_ffi_closure_STDCALL:
.LFB5:
 pushl %ebp
.LCFI9:
 movl %esp, %ebp
.LCFI10:
 subl $40, %esp
 leal -24(%ebp), %edx
 movl %edx, -12(%ebp)
 leal 12(%ebp), %edx
 movl %edx, 4(%esp)
 leal -12(%ebp), %edx
 movl %edx, (%esp)
 call _ffi_closure_SYSV_inner
 movl -12(%ebp), %ecx
0:
 call 1f

.Lscls_store_table:
 .long .Lscls_noretval
 .long .Lscls_retint
 .long .Lscls_retfloat
 .long .Lscls_retdouble
 .long .Lscls_retldouble
 .long .Lscls_retuint8
 .long .Lscls_retsint8
 .long .Lscls_retuint16
 .long .Lscls_retsint16
 .long .Lscls_retint
 .long .Lscls_retint
 .long .Lscls_retllong
 .long .Lscls_retllong
 .long .Lscls_retstruct
 .long .Lscls_retint
 .long .Lscls_retstruct1
 .long .Lscls_retstruct2
 .long .Lscls_retstruct4
1:
 add %eax, %eax
 add %eax, %eax
 add (%esp),%eax
 add $4, %esp
 jmp *(%eax)


.Lscls_retsint8:
 movsbl (%ecx), %eax
 jmp .Lscls_epilogue

.Lscls_retsint16:
 movswl (%ecx), %eax
 jmp .Lscls_epilogue

.Lscls_retuint8:
 movzbl (%ecx), %eax
 jmp .Lscls_epilogue

.Lscls_retuint16:
 movzwl (%ecx), %eax
 jmp .Lscls_epilogue

.Lscls_retint:
 movl (%ecx), %eax
 jmp .Lscls_epilogue

.Lscls_retfloat:
 flds (%ecx)
 jmp .Lscls_epilogue

.Lscls_retdouble:
 fldl (%ecx)
 jmp .Lscls_epilogue

.Lscls_retldouble:
 fldt (%ecx)
 jmp .Lscls_epilogue

.Lscls_retllong:
 movl (%ecx), %eax
 movl 4(%ecx), %edx
 jmp .Lscls_epilogue

.Lscls_retstruct1:
 movsbl (%ecx), %eax
 jmp .Lscls_epilogue

.Lscls_retstruct2:
 movswl (%ecx), %eax
 jmp .Lscls_epilogue

.Lscls_retstruct4:
 movl (%ecx), %eax
 jmp .Lscls_epilogue

.Lscls_retstruct:


.Lscls_noretval:
.Lscls_epilogue:
 movl %ebp, %esp
 popl %ebp
 ret
.ffi_closure_STDCALL_end:
.LFE5:


 .section .eh_frame,"w"

.Lframe1:
.LSCIE1:
 .long .LECIE1-.LASCIE1
.LASCIE1:
 .long 0x0
 .byte 0x1



 .ascii "\0"

 .byte 0x1
 .byte 0x7c
 .byte 0x8




 .byte 0xc
 .byte 0x4
 .byte 0x4
 .byte 0x88
 .byte 0x1
 .align 4
.LECIE1:

.LSFDE1:
 .long .LEFDE1-.LASFDE1
.LASFDE1:
 .long .LASFDE1-.Lframe1



 .long .LFB1

 .long .LFE1-.LFB1





 .byte 0x4
 .long .LCFI0-.LFB1
 .byte 0xe
 .byte 0x8
 .byte 0x85
 .byte 0x2

 .byte 0x4
 .long .LCFI1-.LCFI0
 .byte 0xd
 .byte 0x5


 .align 4
.LEFDE1:


.LSFDE3:
 .long .LEFDE3-.LASFDE3
.LASFDE3:
 .long .LASFDE3-.Lframe1



 .long .LFB3

 .long .LFE3-.LFB3





 .byte 0x4
 .long .LCFI4-.LFB3
 .byte 0xe
 .byte 0x8
 .byte 0x85
 .byte 0x2

 .byte 0x4
 .long .LCFI5-.LCFI4
 .byte 0xd
 .byte 0x5


 .align 4
.LEFDE3:



.LSFDE4:
 .long .LEFDE4-.LASFDE4
.LASFDE4:
 .long .LASFDE4-.Lframe1



 .long .LFB4

 .long .LFE4-.LFB4





 .byte 0x4
 .long .LCFI6-.LFB4
 .byte 0xe
 .byte 0x8
 .byte 0x85
 .byte 0x2

 .byte 0x4
 .long .LCFI7-.LCFI6
 .byte 0xd
 .byte 0x5

 .byte 0x4
 .long .LCFI8-.LCFI7
 .byte 0x86
 .byte 0x3


 .align 4
.LEFDE4:



.LSFDE5:
 .long .LEFDE5-.LASFDE5
.LASFDE5:
 .long .LASFDE5-.Lframe1



 .long .LFB5

 .long .LFE5-.LFB5





 .byte 0x4
 .long .LCFI9-.LFB5
 .byte 0xe
 .byte 0x8
 .byte 0x85
 .byte 0x2

 .byte 0x4
 .long .LCFI10-.LCFI9
 .byte 0xd
 .byte 0x5


 .align 4
.LEFDE5:
