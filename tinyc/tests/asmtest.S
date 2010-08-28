
/* some directive tests */

   .byte 0xff
   .byte 1, 2, 3
   .short 1, 2, 3
   .word 1, 2, 3
   .long 1, 2, 3
   .int 1, 2, 3
   .align 8
   .byte 1
   .align 16, 0x90
   .skip 3
   .skip 15, 0x90
   .string "hello\0world"

/* some label tests */

        movl %eax, %ebx
L1:
        movl %eax, %ebx
        mov 0x10000, %eax
L2:
        movl $L2 - L1, %ecx
var1:
        nop ; nop ; nop ; nop

        mov var1, %eax

/* instruction tests */
movl %eax, %ebx
mov 0x10000, %eax
mov 0x10000, %ax
mov 0x10000, %al
mov %al, 0x10000
                
mov $1, %edx
mov $1, %dx
mov $1, %dl
movb $2, 0x100(%ebx,%edx,2)
movw $2, 0x100(%ebx,%edx,2)
movl $2, 0x100(%ebx,%edx,2)
movl %eax, 0x100(%ebx,%edx,2)
movl 0x100(%ebx,%edx,2), %edx
movw %ax, 0x100(%ebx,%edx,2)

mov %eax, 0x12(,%edx,2)
        
mov %cr3, %edx
mov %ecx, %cr3
movl %cr3, %eax
movl %tr3, %eax
movl %db3, %ebx
movl %dr6, %eax
movl %fs, %ecx
movl %ebx, %fs

     movsbl 0x1000, %eax
     movsbw 0x1000, %ax
     movswl 0x1000, %eax

     movzbl 0x1000, %eax
     movzbw 0x1000, %ax
     movzwl 0x1000, %eax
            
     movzb 0x1000, %eax
     movzb 0x1000, %ax
                
        
  pushl %eax
  pushw %ax
  push %eax
  push %cs
  push %gs
  push $1
  push $100
                                                
  popl %eax
  popw %ax
  pop %eax
  pop %ds
  pop %fs
          
  xchg %eax, %ecx
  xchg %edx, %eax
  xchg %bx, 0x10000
  xchg 0x10000, %ebx
  xchg 0x10000, %dl

  in $100, %al               
  in $100, %ax               
  in $100, %eax
  in %dx, %al
  in %dx, %ax               
  in %dx, %eax
  inb %dx
  inw %dx               
  inl %dx

  out %al, $100                       
  out %ax, $100                       
  out %eax, $100                       

  /* NOTE: gas is bugged here, so size must be added */
  outb %al, %dx                       
  outw %ax, %dx                       
  outl %eax, %dx                       

  leal 0x1000(%ebx), %ecx
  lea 0x1000(%ebx), %ecx

  les 0x2000, %eax
  lds 0x2000, %ebx
  lfs 0x2000, %ecx
  lgs 0x2000, %edx
  lss 0x2000, %edx

addl $0x123, %eax
add $0x123, %ebx
addl $0x123, 0x100
addl $0x123, 0x100(%ebx)
addl $0x123, 0x100(%ebx,%edx,2)
addl $0x123, 0x100(%esp)
addl $0x123, (%ebp)
addl $0x123, (%esp)
cmpl $0x123, (%esp)

add %eax, (%ebx)
add (%ebx), %eax
                
or %dx, (%ebx)
or (%ebx), %si
        
add %cl, (%ebx)
add (%ebx), %dl

    inc %edx
    incl 0x10000
    incb 0x10000
    dec %dx
  
  test $1, %al
  test $1, %cl

  testl $1, 0x1000
  testb $1, 0x1000
  testw $1, 0x1000
  test %eax, %ebx
  test %eax, 0x1000
  test 0x1000, %edx

    not %edx
    notw 0x10000
    notl 0x10000
    notb 0x10000

    neg %edx
    negw 0x10000
    negl 0x10000
    negb 0x10000

    imul %ecx
    mul %edx
    mulb %cl

    imul %eax, %ecx
    imul 0x1000, %cx
    imul $10, %eax, %ecx
    imul $10, %ax, %cx
    imul $10, %eax
    imul $0x1100000, %eax
    imul $1, %eax
    
    idivw 0x1000
    div %ecx
    div %bl
    div %ecx, %eax


shl %edx
shl $10, %edx
shl %cl, %edx

shld $1, %eax, %edx
shld %cl, %eax, %edx
shld %eax, %edx

shrd $1, %eax, %edx
shrd %cl, %eax, %edx
shrd %eax, %edx

L4:
call 0x1000
call L4
call *%eax
call *0x1000
call func1

lcall $0x100, $0x1000

jmp 0x1000
jmp *%eax
jmp *0x1000

ljmp $0x100, $0x1000

ret

ret $10

lret

lret $10

enter $1234, $10

L3:
 jo 0x1000
 jnp 0x1001
 jne 0x1002
 jg 0x1003

 jo L3
 jnp L3
 jne L3
 jg L3

 loopne L3
 loopnz L3
 loope L3
 loopz L3
 loop L3
 jecxz L3

        
 seto %al
 setnp 0x1000
 setl 0xaaaa
 setg %dl

 fadd
 fadd %st(1), %st
 fadd %st(3)

 faddp %st(5)
 faddp
 faddp %st(1), %st

 fadds 0x1000
 fiadds 0x1002
 faddl 0x1004
 fiaddl 0x1006

 fmul
 fmul %st(1), %st
 fmul %st(3)

 fmulp %st(5)
 fmulp
 fmulp %st(1), %st

 fmuls 0x1000
 fimuls 0x1002
 fmull 0x1004
 fimull 0x1006

 fsub
 fsub %st(1), %st
 fsub %st(3)

 fsubp %st(5)
 fsubp
 fsubp %st(1), %st

 fsubs 0x1000
 fisubs 0x1002
 fsubl 0x1004
 fisubl 0x1006

 fsubr
 fsubr %st(1), %st
 fsubr %st(3)

 fsubrp %st(5)
 fsubrp
 fsubrp %st(1), %st

 fsubrs 0x1000
 fisubrs 0x1002
 fsubrl 0x1004
 fisubrl 0x1006

 fdiv
 fdiv %st(1), %st
 fdiv %st(3)

 fdivp %st(5)
 fdivp
 fdivp %st(1), %st

 fdivs 0x1000
 fidivs 0x1002
 fdivl 0x1004
 fidivl 0x1006

 fcom %st(3)

 fcoms 0x1000
 ficoms 0x1002
 fcoml 0x1004
 ficoml 0x1006

 fcomp %st(5)
 fcomp
 fcompp

 fcomps 0x1000
 ficomps 0x1002
 fcompl 0x1004
 ficompl 0x1006

 fld %st(5)
 fldl 0x1000
 flds 0x1002
 fildl 0x1004
 fst %st(4)
 fstp %st(6)
 fstpt 0x1006
 fbstp 0x1008

 fxch
 fxch %st(4)

 fucom %st(6)
 fucomp %st(3)
 fucompp

 finit
 fninit
 fldcw 0x1000
 fnstcw 0x1002
 fstcw 0x1002
 fnstsw 0x1004
 fnstsw %eax
 fstsw 0x1004
 fstsw %eax
 fnclex
 fclex
 fnstenv 0x1000
 fstenv 0x1000
 fldenv 0x1000
 fnsave 0x1002
 fsave 0x1000
 frstor 0x1000
 ffree %st(7)
 ffreep %st(6)
 
    ftst
    fxam
    fld1
    fldl2t
    fldl2e
    fldpi
    fldlg2
    fldln2
    fldz

    f2xm1
    fyl2x
    fptan
    fpatan
    fxtract
    fprem1
    fdecstp
    fincstp
    fprem
    fyl2xp1
    fsqrt
    fsincos
    frndint
    fscale
    fsin
    fcos
    fchs
    fabs
    fnop
    fwait

bswap %edx
xadd %ecx, %edx
xaddb %dl, 0x1000
xaddw %ax, 0x1000
xaddl %eax, 0x1000
cmpxchg %ecx, %edx
cmpxchgb %dl, 0x1000
cmpxchgw %ax, 0x1000
cmpxchgl %eax, 0x1000
invlpg 0x1000
cmpxchg8b 0x1002

fcmovb %st(5), %st
fcmove %st(5), %st
fcmovbe %st(5), %st
fcmovu %st(5), %st
fcmovnb %st(5), %st
fcmovne %st(5), %st
fcmovnbe %st(5), %st
fcmovnu %st(5), %st
fcomi %st(5), %st
fucomi %st(5), %st
fcomip %st(5), %st
fucomip %st(5), %st



 cmovo 0x1000, %eax
 cmovs 0x1000, %eax
 cmovns %edx, %edi

int $3
int $0x10

    pusha
    popa
    clc
    cld
    cli
    clts
    cmc
    lahf
    sahf
    pushfl
    popfl
    pushf
    popf
    stc
    std
    sti
    aaa
    aas
    daa
    das
    aad
    aam
    cbw
    cwd
    cwde
    cdq
    cbtw
    cwtd
    cwtl
    cltd
    leave
    int3
    into
    iret
    rsm
    hlt
    wait
    nop

    /* XXX: handle prefixes */
#if 0
    aword
    addr16
#endif
    lock
    rep
    repe
    repz
    repne
    repnz
    
    invd
    wbinvd
    cpuid
    wrmsr
    rdtsc
    rdmsr
    rdpmc
    ud2

    emms
    movd %edx, %mm3
    movd 0x1000, %mm2
    movd %mm4, %ecx
    movd %mm5, 0x1000
                    
    movq 0x1000, %mm2
    movq %mm4, 0x1000
    
    pand 0x1000, %mm3
    pand %mm4, %mm5
    
    psllw $1, %mm6
    psllw 0x1000, %mm7
    psllw %mm2, %mm7

    xlat
    cmpsb
    scmpw
    insl
    outsw
    lodsb
    slodl
    movsb
    movsl
    smovb
    scasb
    sscaw
    stosw
    sstol

    bsf 0x1000, %ebx
    bsr 0x1000, %ebx
    bt %edx, 0x1000
    btl $2, 0x1000
    btc %edx, 0x1000
    btcl $2, 0x1000
    btr %edx, 0x1000
    btrl $2, 0x1000
    bts %edx, 0x1000
    btsl $2, 0x1000

        
        
    boundl %edx, 0x10000
    boundw %bx, 0x1000
    
    arpl %bx, 0x1000
    lar 0x1000, %eax
    lgdt 0x1000
    lidt 0x1000
    lldt 0x1000
    lmsw 0x1000
    lsl 0x1000, %ecx
    ltr 0x1000
    
    sgdt 0x1000
    sidt 0x1000
    sldt 0x1000
    smsw 0x1000
    str 0x1000
    
    verr 0x1000
    verw 0x1000
  
    push %ds
    pushw %ds
    pushl %ds
    pop %ds
    popw %ds
    popl %ds
    fxsave 1(%ebx)
    fxrstor 1(%ecx)
    pushl $1
    pushw $1
    push $1
