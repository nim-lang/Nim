/* ---------------------------------------------- */
/* alloca86.S */

#include "../config.h"

.globl alloca

alloca:
    pop     %edx
    pop     %eax
    add     $3,%eax
    and     $-4,%eax
    jz      p3

#ifdef TCC_TARGET_PE
p1:
    cmp     $4096,%eax
    jle     p2
    sub     $4096,%esp
    sub     $4096,%eax
    test    %eax,(%esp)
    jmp p1
p2:
#endif

    sub     %eax,%esp
    mov     %esp,%eax
p3:
    push    %edx
    push    %edx
    ret

/* ---------------------------------------------- */
