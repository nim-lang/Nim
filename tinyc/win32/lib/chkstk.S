// =================================================
// chkstk.s

.text
.globl __chkstk

__chkstk:
	xchg    (%esp), %ebp   // store ebp, get ret.addr
	push    %ebp           // push ret.addr
	lea     4(%esp), %ebp  // setup frame ptr
	push    %ecx           // save ecx
	mov     %ebp, %ecx
P0:
	sub     $4096,%ecx
	test    %eax,(%ecx)
	sub     $4096,%eax
	cmp     $4096,%eax
	jge     P0

	sub     %eax,%ecx
	mov     %esp,%eax
	test    %eax,(%ecx)
	mov     %ecx,%esp

	mov     (%eax),%ecx     // restore ecx
	mov     4(%eax),%eax
	push    %eax
	ret

