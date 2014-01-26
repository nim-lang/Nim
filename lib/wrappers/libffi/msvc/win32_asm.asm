/* -----------------------------------------------------------------------
   win32.S - Copyright (c) 1996, 1998, 2001, 2002, 2009  Red Hat, Inc.
	     Copyright (c) 2001  John Beniton
	     Copyright (c) 2002  Ranjit Mathew
	     Copyright (c) 2009  Daniel Witte
			
 
   X86 Foreign Function Interface
 
   Permission is hereby granted, free of charge, to any person obtaining
   a copy of this software and associated documentation files (the
   ``Software''), to deal in the Software without restriction, including
   without limitation the rights to use, copy, modify, merge, publish,
   distribute, sublicense, and/or sell copies of the Software, and to
   permit persons to whom the Software is furnished to do so, subject to
   the following conditions:
 
   The above copyright notice and this permission notice shall be included
   in all copies or substantial portions of the Software.
 
   THE SOFTWARE IS PROVIDED ``AS IS'', WITHOUT WARRANTY OF ANY KIND,
   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
   NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
   HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
   WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
   DEALINGS IN THE SOFTWARE.
   -----------------------------------------------------------------------
   */
 
#define LIBFFI_ASM
#include <fficonfig.h>
#include <ffi.h>

.386
.MODEL FLAT, C

EXTRN ffi_closure_SYSV_inner:NEAR

_TEXT SEGMENT

ffi_call_win32 PROC NEAR,
    ffi_prep_args : NEAR PTR DWORD,
    ecif          : NEAR PTR DWORD,
    cif_abi       : DWORD,
    cif_bytes     : DWORD,
    cif_flags     : DWORD,
    rvalue        : NEAR PTR DWORD,
    fn            : NEAR PTR DWORD

        ;; Make room for all of the new args.
        mov  ecx, cif_bytes
        sub  esp, ecx

        mov  eax, esp

        ;; Place all of the ffi_prep_args in position
        push ecif
        push eax
        call ffi_prep_args

        ;; Return stack to previous state and call the function
        add  esp, 8

	;; Handle thiscall and fastcall
	cmp cif_abi, 3 ;; FFI_THISCALL
	jz do_thiscall
	cmp cif_abi, 4 ;; FFI_FASTCALL
	jnz do_stdcall
	mov ecx, DWORD PTR [esp]
	mov edx, DWORD PTR [esp+4]
	add esp, 8
	jmp do_stdcall
do_thiscall:
	mov ecx, DWORD PTR [esp]
	add esp, 4
do_stdcall:
        call fn

        ;; cdecl:   we restore esp in the epilogue, so there's no need to
        ;;          remove the space we pushed for the args.
        ;; stdcall: the callee has already cleaned the stack.

        ;; Load ecx with the return type code
        mov  ecx, cif_flags

        ;; If the return value pointer is NULL, assume no return value.
        cmp  rvalue, 0
        jne  ca_jumptable

        ;; Even if there is no space for the return value, we are
        ;; obliged to handle floating-point values.
        cmp  ecx, FFI_TYPE_FLOAT
        jne  ca_epilogue
        fstp st(0)

        jmp  ca_epilogue

ca_jumptable:
        jmp  [ca_jumpdata + 4 * ecx]
ca_jumpdata:
        ;; Do not insert anything here between label and jump table.
        dd offset ca_epilogue       ;; FFI_TYPE_VOID
        dd offset ca_retint         ;; FFI_TYPE_INT
        dd offset ca_retfloat       ;; FFI_TYPE_FLOAT
        dd offset ca_retdouble      ;; FFI_TYPE_DOUBLE
        dd offset ca_retlongdouble  ;; FFI_TYPE_LONGDOUBLE
        dd offset ca_retuint8       ;; FFI_TYPE_UINT8
        dd offset ca_retsint8       ;; FFI_TYPE_SINT8
        dd offset ca_retuint16      ;; FFI_TYPE_UINT16
        dd offset ca_retsint16      ;; FFI_TYPE_SINT16
        dd offset ca_retint         ;; FFI_TYPE_UINT32
        dd offset ca_retint         ;; FFI_TYPE_SINT32
        dd offset ca_retint64       ;; FFI_TYPE_UINT64
        dd offset ca_retint64       ;; FFI_TYPE_SINT64
        dd offset ca_epilogue       ;; FFI_TYPE_STRUCT
        dd offset ca_retint         ;; FFI_TYPE_POINTER
        dd offset ca_retstruct1b    ;; FFI_TYPE_SMALL_STRUCT_1B
        dd offset ca_retstruct2b    ;; FFI_TYPE_SMALL_STRUCT_2B
        dd offset ca_retint         ;; FFI_TYPE_SMALL_STRUCT_4B
        dd offset ca_epilogue       ;; FFI_TYPE_MS_STRUCT

        /* Sign/zero extend as appropriate.  */
ca_retuint8:
        movzx eax, al
        jmp   ca_retint

ca_retsint8:
        movsx eax, al
        jmp   ca_retint

ca_retuint16:
        movzx eax, ax
        jmp   ca_retint

ca_retsint16:
        movsx eax, ax
        jmp   ca_retint

ca_retint:
        ;; Load %ecx with the pointer to storage for the return value
        mov   ecx, rvalue
        mov   [ecx + 0], eax
        jmp   ca_epilogue

ca_retint64:
        ;; Load %ecx with the pointer to storage for the return value
        mov   ecx, rvalue
        mov   [ecx + 0], eax
        mov   [ecx + 4], edx
        jmp   ca_epilogue

ca_retfloat:
        ;; Load %ecx with the pointer to storage for the return value
        mov   ecx, rvalue
        fstp  DWORD PTR [ecx]
        jmp   ca_epilogue

ca_retdouble:
        ;; Load %ecx with the pointer to storage for the return value
        mov   ecx, rvalue
        fstp  QWORD PTR [ecx]
        jmp   ca_epilogue

ca_retlongdouble:
        ;; Load %ecx with the pointer to storage for the return value
        mov   ecx, rvalue
        fstp  TBYTE PTR [ecx]
        jmp   ca_epilogue

ca_retstruct1b:
        ;; Load %ecx with the pointer to storage for the return value
        mov   ecx, rvalue
        mov   [ecx + 0], al
        jmp   ca_epilogue

ca_retstruct2b:
        ;; Load %ecx with the pointer to storage for the return value
        mov   ecx, rvalue
        mov   [ecx + 0], ax
        jmp   ca_epilogue

ca_epilogue:
        ;; Epilogue code is autogenerated.
        ret
ffi_call_win32 ENDP

ffi_closure_THISCALL PROC NEAR FORCEFRAME
	sub	esp, 40
	lea	edx, [ebp -24]
	mov	[ebp - 12], edx	/* resp */
	lea	edx, [ebp + 12]  /* account for stub return address on stack */
	jmp	stub
ffi_closure_THISCALL ENDP

ffi_closure_SYSV PROC NEAR FORCEFRAME
    ;; the ffi_closure ctx is passed in eax by the trampoline.

        sub  esp, 40
        lea  edx, [ebp - 24]
        mov  [ebp - 12], edx         ;; resp
        lea  edx, [ebp + 8]
stub::
        mov  [esp + 8], edx          ;; args
        lea  edx, [ebp - 12]
        mov  [esp + 4], edx          ;; &resp
        mov  [esp], eax              ;; closure
        call ffi_closure_SYSV_inner
        mov  ecx, [ebp - 12]

cs_jumptable:
        jmp  [cs_jumpdata + 4 * eax]
cs_jumpdata:
        ;; Do not insert anything here between the label and jump table.
        dd offset cs_epilogue       ;; FFI_TYPE_VOID
        dd offset cs_retint         ;; FFI_TYPE_INT
        dd offset cs_retfloat       ;; FFI_TYPE_FLOAT
        dd offset cs_retdouble      ;; FFI_TYPE_DOUBLE
        dd offset cs_retlongdouble  ;; FFI_TYPE_LONGDOUBLE
        dd offset cs_retuint8       ;; FFI_TYPE_UINT8
        dd offset cs_retsint8       ;; FFI_TYPE_SINT8
        dd offset cs_retuint16      ;; FFI_TYPE_UINT16
        dd offset cs_retsint16      ;; FFI_TYPE_SINT16
        dd offset cs_retint         ;; FFI_TYPE_UINT32
        dd offset cs_retint         ;; FFI_TYPE_SINT32
        dd offset cs_retint64       ;; FFI_TYPE_UINT64
        dd offset cs_retint64       ;; FFI_TYPE_SINT64
        dd offset cs_retstruct      ;; FFI_TYPE_STRUCT
        dd offset cs_retint         ;; FFI_TYPE_POINTER
        dd offset cs_retsint8       ;; FFI_TYPE_SMALL_STRUCT_1B
        dd offset cs_retsint16      ;; FFI_TYPE_SMALL_STRUCT_2B
        dd offset cs_retint         ;; FFI_TYPE_SMALL_STRUCT_4B
        dd offset cs_retmsstruct    ;; FFI_TYPE_MS_STRUCT

cs_retuint8:
        movzx eax, BYTE PTR [ecx]
        jmp   cs_epilogue

cs_retsint8:
        movsx eax, BYTE PTR [ecx]
        jmp   cs_epilogue

cs_retuint16:
        movzx eax, WORD PTR [ecx]
        jmp   cs_epilogue

cs_retsint16:
        movsx eax, WORD PTR [ecx]
        jmp   cs_epilogue

cs_retint:
        mov   eax, [ecx]
        jmp   cs_epilogue

cs_retint64:
        mov   eax, [ecx + 0]
        mov   edx, [ecx + 4]
        jmp   cs_epilogue

cs_retfloat:
        fld   DWORD PTR [ecx]
        jmp   cs_epilogue

cs_retdouble:
        fld   QWORD PTR [ecx]
        jmp   cs_epilogue

cs_retlongdouble:
        fld   TBYTE PTR [ecx]
        jmp   cs_epilogue

cs_retstruct:
        ;; Caller expects us to pop struct return value pointer hidden arg.
        ;; Epilogue code is autogenerated.
        ret	4

cs_retmsstruct:
        ;; Caller expects us to return a pointer to the real return value.
        mov   eax, ecx
        ;; Caller doesn't expects us to pop struct return value pointer hidden arg.
        jmp   cs_epilogue

cs_epilogue:
        ;; Epilogue code is autogenerated.
        ret
ffi_closure_SYSV ENDP

#if !FFI_NO_RAW_API

#define RAW_CLOSURE_CIF_OFFSET ((FFI_TRAMPOLINE_SIZE + 3) AND NOT 3)
#define RAW_CLOSURE_FUN_OFFSET (RAW_CLOSURE_CIF_OFFSET + 4)
#define RAW_CLOSURE_USER_DATA_OFFSET (RAW_CLOSURE_FUN_OFFSET + 4)
#define CIF_FLAGS_OFFSET 20

ffi_closure_raw_THISCALL PROC NEAR USES esi FORCEFRAME
	sub esp, 36
	mov  esi, [eax + RAW_CLOSURE_CIF_OFFSET]        ;; closure->cif
	mov  edx, [eax + RAW_CLOSURE_USER_DATA_OFFSET]  ;; closure->user_data
	mov [esp + 12], edx
	lea edx, [ebp + 12]
	jmp stubraw
ffi_closure_raw_THISCALL ENDP

ffi_closure_raw_SYSV PROC NEAR USES esi FORCEFRAME
    ;; the ffi_closure ctx is passed in eax by the trampoline.

        sub  esp, 40
        mov  esi, [eax + RAW_CLOSURE_CIF_OFFSET]        ;; closure->cif
        mov  edx, [eax + RAW_CLOSURE_USER_DATA_OFFSET]  ;; closure->user_data
        mov  [esp + 12], edx                            ;; user_data
        lea  edx, [ebp + 8]
stubraw::
        mov  [esp + 8], edx                             ;; raw_args
        lea  edx, [ebp - 24]
        mov  [esp + 4], edx                             ;; &res
        mov  [esp], esi                                 ;; cif
        call DWORD PTR [eax + RAW_CLOSURE_FUN_OFFSET]   ;; closure->fun
        mov  eax, [esi + CIF_FLAGS_OFFSET]              ;; cif->flags
        lea  ecx, [ebp - 24]

cr_jumptable:
        jmp  [cr_jumpdata + 4 * eax]
cr_jumpdata:
        ;; Do not insert anything here between the label and jump table.
        dd offset cr_epilogue       ;; FFI_TYPE_VOID
        dd offset cr_retint         ;; FFI_TYPE_INT
        dd offset cr_retfloat       ;; FFI_TYPE_FLOAT
        dd offset cr_retdouble      ;; FFI_TYPE_DOUBLE
        dd offset cr_retlongdouble  ;; FFI_TYPE_LONGDOUBLE
        dd offset cr_retuint8       ;; FFI_TYPE_UINT8
        dd offset cr_retsint8       ;; FFI_TYPE_SINT8
        dd offset cr_retuint16      ;; FFI_TYPE_UINT16
        dd offset cr_retsint16      ;; FFI_TYPE_SINT16
        dd offset cr_retint         ;; FFI_TYPE_UINT32
        dd offset cr_retint         ;; FFI_TYPE_SINT32
        dd offset cr_retint64       ;; FFI_TYPE_UINT64
        dd offset cr_retint64       ;; FFI_TYPE_SINT64
        dd offset cr_epilogue       ;; FFI_TYPE_STRUCT
        dd offset cr_retint         ;; FFI_TYPE_POINTER
        dd offset cr_retsint8       ;; FFI_TYPE_SMALL_STRUCT_1B
        dd offset cr_retsint16      ;; FFI_TYPE_SMALL_STRUCT_2B
        dd offset cr_retint         ;; FFI_TYPE_SMALL_STRUCT_4B
        dd offset cr_epilogue       ;; FFI_TYPE_MS_STRUCT

cr_retuint8:
        movzx eax, BYTE PTR [ecx]
        jmp   cr_epilogue

cr_retsint8:
        movsx eax, BYTE PTR [ecx]
        jmp   cr_epilogue

cr_retuint16:
        movzx eax, WORD PTR [ecx]
        jmp   cr_epilogue

cr_retsint16:
        movsx eax, WORD PTR [ecx]
        jmp   cr_epilogue

cr_retint:
        mov   eax, [ecx]
        jmp   cr_epilogue

cr_retint64:
        mov   eax, [ecx + 0]
        mov   edx, [ecx + 4]
        jmp   cr_epilogue

cr_retfloat:
        fld   DWORD PTR [ecx]
        jmp   cr_epilogue

cr_retdouble:
        fld   QWORD PTR [ecx]
        jmp   cr_epilogue

cr_retlongdouble:
        fld   TBYTE PTR [ecx]
        jmp   cr_epilogue

cr_epilogue:
        ;; Epilogue code is autogenerated.
        ret
ffi_closure_raw_SYSV ENDP

#endif /* !FFI_NO_RAW_API */

ffi_closure_STDCALL PROC NEAR FORCEFRAME
    ;; the ffi_closure ctx is passed in eax by the trampoline.

        sub  esp, 40
        lea  edx, [ebp - 24]
        mov  [ebp - 12], edx         ;; resp
        lea  edx, [ebp + 12]         ;; account for stub return address on stack
        mov  [esp + 8], edx          ;; args
        lea  edx, [ebp - 12]
        mov  [esp + 4], edx          ;; &resp
        mov  [esp], eax              ;; closure
        call ffi_closure_SYSV_inner
        mov  ecx, [ebp - 12]

cd_jumptable:
        jmp  [cd_jumpdata + 4 * eax]
cd_jumpdata:
        ;; Do not insert anything here between the label and jump table.
        dd offset cd_epilogue       ;; FFI_TYPE_VOID
        dd offset cd_retint         ;; FFI_TYPE_INT
        dd offset cd_retfloat       ;; FFI_TYPE_FLOAT
        dd offset cd_retdouble      ;; FFI_TYPE_DOUBLE
        dd offset cd_retlongdouble  ;; FFI_TYPE_LONGDOUBLE
        dd offset cd_retuint8       ;; FFI_TYPE_UINT8
        dd offset cd_retsint8       ;; FFI_TYPE_SINT8
        dd offset cd_retuint16      ;; FFI_TYPE_UINT16
        dd offset cd_retsint16      ;; FFI_TYPE_SINT16
        dd offset cd_retint         ;; FFI_TYPE_UINT32
        dd offset cd_retint         ;; FFI_TYPE_SINT32
        dd offset cd_retint64       ;; FFI_TYPE_UINT64
        dd offset cd_retint64       ;; FFI_TYPE_SINT64
        dd offset cd_epilogue       ;; FFI_TYPE_STRUCT
        dd offset cd_retint         ;; FFI_TYPE_POINTER
        dd offset cd_retsint8       ;; FFI_TYPE_SMALL_STRUCT_1B
        dd offset cd_retsint16      ;; FFI_TYPE_SMALL_STRUCT_2B
        dd offset cd_retint         ;; FFI_TYPE_SMALL_STRUCT_4B

cd_retuint8:
        movzx eax, BYTE PTR [ecx]
        jmp   cd_epilogue

cd_retsint8:
        movsx eax, BYTE PTR [ecx]
        jmp   cd_epilogue

cd_retuint16:
        movzx eax, WORD PTR [ecx]
        jmp   cd_epilogue

cd_retsint16:
        movsx eax, WORD PTR [ecx]
        jmp   cd_epilogue

cd_retint:
        mov   eax, [ecx]
        jmp   cd_epilogue

cd_retint64:
        mov   eax, [ecx + 0]
        mov   edx, [ecx + 4]
        jmp   cd_epilogue

cd_retfloat:
        fld   DWORD PTR [ecx]
        jmp   cd_epilogue

cd_retdouble:
        fld   QWORD PTR [ecx]
        jmp   cd_epilogue

cd_retlongdouble:
        fld   TBYTE PTR [ecx]
        jmp   cd_epilogue

cd_epilogue:
        ;; Epilogue code is autogenerated.
        ret
ffi_closure_STDCALL ENDP

_TEXT ENDS
END
