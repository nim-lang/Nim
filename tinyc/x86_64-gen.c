/*
 *  x86-64 code generator for TCC
 *
 *  Copyright (c) 2008 Shinichiro Hamaji
 *
 *  Based on i386-gen.c by Fabrice Bellard
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#include <assert.h>

/* number of available registers */
#define NB_REGS             5

/* a register can belong to several classes. The classes must be
   sorted from more general to more precise (see gv2() code which does
   assumptions on it). */
#define RC_INT     0x0001 /* generic integer register */
#define RC_FLOAT   0x0002 /* generic float register */
#define RC_RAX     0x0004
#define RC_RCX     0x0008
#define RC_RDX     0x0010
#define RC_XMM0    0x0020
#define RC_ST0     0x0040 /* only for long double */
#define RC_IRET    RC_RAX /* function return: integer register */
#define RC_LRET    RC_RDX /* function return: second integer register */
#define RC_FRET    RC_XMM0 /* function return: float register */

/* pretty names for the registers */
enum {
    TREG_RAX = 0,
    TREG_RCX = 1,
    TREG_RDX = 2,
    TREG_RSI = 6,
    TREG_RDI = 7,
    TREG_R8  = 8,
    TREG_R9  = 9,
    TREG_R10 = 10,
    TREG_R11 = 11,

    TREG_XMM0 = 3,
    TREG_ST0 = 4,

    TREG_MEM = 0x10,
};

#define REX_BASE(reg) (((reg) >> 3) & 1)
#define REG_VALUE(reg) ((reg) & 7)

int reg_classes[NB_REGS] = {
    /* eax */ RC_INT | RC_RAX,
    /* ecx */ RC_INT | RC_RCX,
    /* edx */ RC_INT | RC_RDX,
    /* xmm0 */ RC_FLOAT | RC_XMM0,
    /* st0 */ RC_ST0,
};

/* return registers for function */
#define REG_IRET TREG_RAX /* single word int return register */
#define REG_LRET TREG_RDX /* second word return register (for long long) */
#define REG_FRET TREG_XMM0 /* float return register */

/* defined if function parameters must be evaluated in reverse order */
#define INVERT_FUNC_PARAMS

/* pointer size, in bytes */
#define PTR_SIZE 8

/* long double size and alignment, in bytes */
#define LDOUBLE_SIZE  16
#define LDOUBLE_ALIGN 8
/* maximum alignment (for aligned attribute support) */
#define MAX_ALIGN     8

/******************************************************/
/* ELF defines */

#define EM_TCC_TARGET EM_X86_64

/* relocation type for 32 bit data relocation */
#define R_DATA_32   R_X86_64_64
#define R_JMP_SLOT  R_X86_64_JUMP_SLOT
#define R_COPY      R_X86_64_COPY

#define ELF_START_ADDR 0x08048000
#define ELF_PAGE_SIZE  0x1000

/******************************************************/

static unsigned long func_sub_sp_offset;
static int func_ret_sub;

/* XXX: make it faster ? */
void g(int c)
{
    int ind1;
    ind1 = ind + 1;
    if (ind1 > cur_text_section->data_allocated)
        section_realloc(cur_text_section, ind1);
    cur_text_section->data[ind] = c;
    ind = ind1;
}

void o(unsigned int c)
{
    while (c) {
        g(c);
        c = c >> 8;
    }
}

void gen_le32(int c)
{
    g(c);
    g(c >> 8);
    g(c >> 16);
    g(c >> 24);
}

void gen_le64(int64_t c)
{
    g(c);
    g(c >> 8);
    g(c >> 16);
    g(c >> 24);
    g(c >> 32);
    g(c >> 40);
    g(c >> 48);
    g(c >> 56);
}

/* output a symbol and patch all calls to it */
void gsym_addr(int t, int a)
{
    int n, *ptr;
    while (t) {
        ptr = (int *)(cur_text_section->data + t);
        n = *ptr; /* next value */
        *ptr = a - t - 4;
        t = n;
    }
}

void gsym(int t)
{
    gsym_addr(t, ind);
}

/* psym is used to put an instruction with a data field which is a
   reference to a symbol. It is in fact the same as oad ! */
#define psym oad

static int is64_type(int t)
{
    return ((t & VT_BTYPE) == VT_PTR ||
            (t & VT_BTYPE) == VT_FUNC ||
            (t & VT_BTYPE) == VT_LLONG);
}

static int is_sse_float(int t) {
    int bt;
    bt = t & VT_BTYPE;
    return bt == VT_DOUBLE || bt == VT_FLOAT;
}

/* instruction + 4 bytes data. Return the address of the data */
static int oad(int c, int s)
{
    int ind1;

    o(c);
    ind1 = ind + 4;
    if (ind1 > cur_text_section->data_allocated)
        section_realloc(cur_text_section, ind1);
    *(int *)(cur_text_section->data + ind) = s;
    s = ind;
    ind = ind1;
    return s;
}

/* output constant with relocation if 'r & VT_SYM' is true */
static void gen_addr64(int r, Sym *sym, int64_t c)
{
    if (r & VT_SYM)
        greloc(cur_text_section, sym, ind, R_X86_64_64);
    gen_le64(c);
}

/* output constant with relocation if 'r & VT_SYM' is true */
static void gen_addrpc32(int r, Sym *sym, int c)
{
    if (r & VT_SYM)
        greloc(cur_text_section, sym, ind, R_X86_64_PC32);
    gen_le32(c-4);
}

/* output got address with relocation */
static void gen_gotpcrel(int r, Sym *sym, int c)
{
    Section *sr;
    ElfW(Rela) *rel;
    greloc(cur_text_section, sym, ind, R_X86_64_GOTPCREL);
    sr = cur_text_section->reloc;
    rel = (ElfW(Rela) *)(sr->data + sr->data_offset - sizeof(ElfW(Rela)));
    rel->r_addend = -4;
    gen_le32(0);

    if (c) {
        /* we use add c, %xxx for displacement */
        o(0x48 + REX_BASE(r));
        o(0x81);
        o(0xc0 + REG_VALUE(r));
        gen_le32(c);
    }
}

static void gen_modrm_impl(int op_reg, int r, Sym *sym, int c, int is_got)
{
    op_reg = REG_VALUE(op_reg) << 3;
    if ((r & VT_VALMASK) == VT_CONST) {
        /* constant memory reference */
        o(0x05 | op_reg);
        if (is_got) {
            gen_gotpcrel(r, sym, c);
        } else {
            gen_addrpc32(r, sym, c);
        }
    } else if ((r & VT_VALMASK) == VT_LOCAL) {
        /* currently, we use only ebp as base */
        if (c == (char)c) {
            /* short reference */
            o(0x45 | op_reg);
            g(c);
        } else {
            oad(0x85 | op_reg, c);
        }
    } else if ((r & VT_VALMASK) >= TREG_MEM) {
        if (c) {
            g(0x80 | op_reg | REG_VALUE(r));
            gen_le32(c);
        } else {
            g(0x00 | op_reg | REG_VALUE(r));
        }
    } else {
        g(0x00 | op_reg | (r & VT_VALMASK));
    }
}

/* generate a modrm reference. 'op_reg' contains the addtionnal 3
   opcode bits */
static void gen_modrm(int op_reg, int r, Sym *sym, int c)
{
    gen_modrm_impl(op_reg, r, sym, c, 0);
}

/* generate a modrm reference. 'op_reg' contains the addtionnal 3
   opcode bits */
static void gen_modrm64(int opcode, int op_reg, int r, Sym *sym, int c)
{
    int is_got;
    int rex = 0x48 | (REX_BASE(op_reg) << 2);
    if ((r & VT_VALMASK) != VT_CONST &&
        (r & VT_VALMASK) != VT_LOCAL) {
        rex |= REX_BASE(VT_VALMASK & r);
    }
    o(rex);
    o(opcode);
    is_got = (op_reg & TREG_MEM) && !(sym->type.t & VT_STATIC);
    gen_modrm_impl(op_reg, r, sym, c, is_got);
}


/* load 'r' from value 'sv' */
void load(int r, SValue *sv)
{
    int v, t, ft, fc, fr;
    SValue v1;

    fr = sv->r;
    ft = sv->type.t;
    fc = sv->c.ul;

    /* we use indirect access via got */
    if ((fr & VT_VALMASK) == VT_CONST && (fr & VT_SYM) &&
        (fr & VT_LVAL) && !(sv->sym->type.t & VT_STATIC)) {
        /* use the result register as a temporal register */
        int tr = r | TREG_MEM;
        if (is_float(ft)) {
            /* we cannot use float registers as a temporal register */
            tr = get_reg(RC_INT) | TREG_MEM;
        }
        gen_modrm64(0x8b, tr, fr, sv->sym, 0);

        /* load from the temporal register */
        fr = tr | VT_LVAL;
    }

    v = fr & VT_VALMASK;
    if (fr & VT_LVAL) {
        if (v == VT_LLOCAL) {
            v1.type.t = VT_PTR;
            v1.r = VT_LOCAL | VT_LVAL;
            v1.c.ul = fc;
            load(r, &v1);
            fr = r;
        }
        if ((ft & VT_BTYPE) == VT_FLOAT) {
            o(0x6e0f66); /* movd */
            r = 0;
        } else if ((ft & VT_BTYPE) == VT_DOUBLE) {
            o(0x7e0ff3); /* movq */
            r = 0;
        } else if ((ft & VT_BTYPE) == VT_LDOUBLE) {
            o(0xdb); /* fldt */
            r = 5;
        } else if ((ft & VT_TYPE) == VT_BYTE) {
            o(0xbe0f);   /* movsbl */
        } else if ((ft & VT_TYPE) == (VT_BYTE | VT_UNSIGNED)) {
            o(0xb60f);   /* movzbl */
        } else if ((ft & VT_TYPE) == VT_SHORT) {
            o(0xbf0f);   /* movswl */
        } else if ((ft & VT_TYPE) == (VT_SHORT | VT_UNSIGNED)) {
            o(0xb70f);   /* movzwl */
        } else if (is64_type(ft)) {
            gen_modrm64(0x8b, r, fr, sv->sym, fc);
            return;
        } else {
            o(0x8b);   /* movl */
        }
        gen_modrm(r, fr, sv->sym, fc);
    } else {
        if (v == VT_CONST) {
            if ((ft & VT_BTYPE) == VT_LLONG) {
                assert(!(fr & VT_SYM));
                o(0x48);
                o(0xb8 + REG_VALUE(r)); /* mov $xx, r */
                gen_addr64(fr, sv->sym, sv->c.ull);
            } else {
                if (fr & VT_SYM) {
                    if (sv->sym->type.t & VT_STATIC) {
                        o(0x8d48);
                        o(0x05 + REG_VALUE(r) * 8); /* lea xx(%rip), r */
                        gen_addrpc32(fr, sv->sym, fc);
                    } else {
                        o(0x8b48);
                        o(0x05 + REG_VALUE(r) * 8); /* mov xx(%rip), r */
                        gen_gotpcrel(r, sv->sym, fc);
                    }
                } else {
                    o(0xb8 + REG_VALUE(r)); /* mov $xx, r */
                    gen_le32(fc);
                }
            }
        } else if (v == VT_LOCAL) {
            o(0x48 | REX_BASE(r));
            o(0x8d); /* lea xxx(%ebp), r */
            gen_modrm(r, VT_LOCAL, sv->sym, fc);
        } else if (v == VT_CMP) {
            oad(0xb8 + r, 0); /* mov $0, r */
            o(0x0f); /* setxx %br */
            o(fc);
            o(0xc0 + r);
        } else if (v == VT_JMP || v == VT_JMPI) {
            t = v & 1;
            oad(0xb8 + r, t); /* mov $1, r */
            o(0x05eb); /* jmp after */
            gsym(fc);
            oad(0xb8 + r, t ^ 1); /* mov $0, r */
        } else if (v != r) {
            if (r == TREG_XMM0) {
                assert(v == TREG_ST0);
                /* gen_cvt_ftof(VT_DOUBLE); */
                o(0xf0245cdd); /* fstpl -0x10(%rsp) */
                /* movsd -0x10(%rsp),%xmm0 */
                o(0x44100ff2);
                o(0xf024);
            } else if (r == TREG_ST0) {
                assert(v == TREG_XMM0);
                /* gen_cvt_ftof(VT_LDOUBLE); */
                /* movsd %xmm0,-0x10(%rsp) */
                o(0x44110ff2);
                o(0xf024);
                o(0xf02444dd); /* fldl -0x10(%rsp) */
            } else {
                o(0x48 | REX_BASE(r) | (REX_BASE(v) << 2));
                o(0x89);
                o(0xc0 + r + v * 8); /* mov v, r */
            }
        }
    }
}

/* store register 'r' in lvalue 'v' */
void store(int r, SValue *v)
{
    int fr, bt, ft, fc;
    int op64 = 0;
    /* store the REX prefix in this variable when PIC is enabled */
    int pic = 0;

    ft = v->type.t;
    fc = v->c.ul;
    fr = v->r & VT_VALMASK;
    bt = ft & VT_BTYPE;

    /* we need to access the variable via got */
    if (fr == VT_CONST && (v->r & VT_SYM)) {
        /* mov xx(%rip), %r11 */
        o(0x1d8b4c);
        gen_gotpcrel(TREG_R11, v->sym, v->c.ul);
        pic = is64_type(bt) ? 0x49 : 0x41;
    }

    /* XXX: incorrect if float reg to reg */
    if (bt == VT_FLOAT) {
        o(0x66);
        o(pic);
        o(0x7e0f); /* movd */
        r = 0;
    } else if (bt == VT_DOUBLE) {
        o(0x66);
        o(pic);
        o(0xd60f); /* movq */
        r = 0;
    } else if (bt == VT_LDOUBLE) {
        o(0xc0d9); /* fld %st(0) */
        o(pic);
        o(0xdb); /* fstpt */
        r = 7;
    } else {
        if (bt == VT_SHORT)
            o(0x66);
        o(pic);
        if (bt == VT_BYTE || bt == VT_BOOL)
            o(0x88);
        else if (is64_type(bt))
            op64 = 0x89;
        else
            o(0x89);
    }
    if (pic) {
        /* xxx r, (%r11) where xxx is mov, movq, fld, or etc */
        if (op64)
            o(op64);
        o(3 + (r << 3));
    } else if (op64) {
        if (fr == VT_CONST ||
            fr == VT_LOCAL ||
            (v->r & VT_LVAL)) {
            gen_modrm64(op64, r, v->r, v->sym, fc);
        } else if (fr != r) {
            /* XXX: don't we really come here? */
            abort();
            o(0xc0 + fr + r * 8); /* mov r, fr */
        }
    } else {
        if (fr == VT_CONST ||
            fr == VT_LOCAL ||
            (v->r & VT_LVAL)) {
            gen_modrm(r, v->r, v->sym, fc);
        } else if (fr != r) {
            /* XXX: don't we really come here? */
            abort();
            o(0xc0 + fr + r * 8); /* mov r, fr */
        }
    }
}

static void gadd_sp(int val)
{
    if (val == (char)val) {
        o(0xc48348);
        g(val);
    } else {
        oad(0xc48148, val); /* add $xxx, %rsp */
    }
}

/* 'is_jmp' is '1' if it is a jump */
static void gcall_or_jmp(int is_jmp)
{
    int r;
    if ((vtop->r & (VT_VALMASK | VT_LVAL)) == VT_CONST) {
        /* constant case */
        if (vtop->r & VT_SYM) {
            /* relocation case */
            greloc(cur_text_section, vtop->sym,
                   ind + 1, R_X86_64_PC32);
        } else {
            /* put an empty PC32 relocation */
            put_elf_reloc(symtab_section, cur_text_section,
                          ind + 1, R_X86_64_PC32, 0);
        }
        oad(0xe8 + is_jmp, vtop->c.ul - 4); /* call/jmp im */
    } else {
        /* otherwise, indirect call */
        r = TREG_R11;
        load(r, vtop);
        o(0x41); /* REX */
        o(0xff); /* call/jmp *r */
        o(0xd0 + REG_VALUE(r) + (is_jmp << 4));
    }
}

static uint8_t arg_regs[6] = {
    TREG_RDI, TREG_RSI, TREG_RDX, TREG_RCX, TREG_R8, TREG_R9
};
/* Generate function call. The function address is pushed first, then
   all the parameters in call order. This functions pops all the
   parameters and the function address. */
void gfunc_call(int nb_args)
{
    int size, align, r, args_size, i, func_call;
    Sym *func_sym;
    SValue *orig_vtop;
    int nb_reg_args = 0;
    int nb_sse_args = 0;
    int sse_reg, gen_reg;

    /* calculate the number of integer/float arguments */
    args_size = 0;
    for(i = 0; i < nb_args; i++) {
        if ((vtop[-i].type.t & VT_BTYPE) == VT_STRUCT) {
            args_size += type_size(&vtop->type, &align);
        } else if ((vtop[-i].type.t & VT_BTYPE) == VT_LDOUBLE) {
            args_size += 16;
        } else if (is_sse_float(vtop[-i].type.t)) {
            nb_sse_args++;
            if (nb_sse_args > 8) args_size += 8;
        } else {
            nb_reg_args++;
            if (nb_reg_args > 6) args_size += 8;
        }
    }

    /* for struct arguments, we need to call memcpy and the function
       call breaks register passing arguments we are preparing.
       So, we process arguments which will be passed by stack first. */
    orig_vtop = vtop;
    gen_reg = nb_reg_args;
    sse_reg = nb_sse_args;
    /* adjust stack to align SSE boundary */
    if (args_size &= 8) {
        o(0x50); /* push $rax */
    }
    for(i = 0; i < nb_args; i++) {
        if ((vtop->type.t & VT_BTYPE) == VT_STRUCT) {
            size = type_size(&vtop->type, &align);
            /* align to stack align size */
            size = (size + 3) & ~3;
            /* allocate the necessary size on stack */
            o(0x48);
            oad(0xec81, size); /* sub $xxx, %rsp */
            /* generate structure store */
            r = get_reg(RC_INT);
            o(0x48 + REX_BASE(r));
            o(0x89); /* mov %rsp, r */
            o(0xe0 + r);
            {
                /* following code breaks vtop[1] */
                SValue tmp = vtop[1];
                vset(&vtop->type, r | VT_LVAL, 0);
                vswap();
                vstore();
                vtop[1] = tmp;
            }
            args_size += size;
        } else if ((vtop->type.t & VT_BTYPE) == VT_LDOUBLE) {
            gv(RC_ST0);
            size = LDOUBLE_SIZE;
            oad(0xec8148, size); /* sub $xxx, %rsp */
            o(0x7cdb); /* fstpt 0(%rsp) */
            g(0x24);
            g(0x00);
            args_size += size;
        } else if (is_sse_float(vtop->type.t)) {
            int j = --sse_reg;
            if (j >= 8) {
                gv(RC_FLOAT);
                o(0x50); /* push $rax */
                /* movq %xmm0, (%rsp) */
                o(0x04d60f66);
                o(0x24);
                args_size += 8;
            }
        } else {
            int j = --gen_reg;
            /* simple type */
            /* XXX: implicit cast ? */
            if (j >= 6) {
                r = gv(RC_INT);
                o(0x50 + r); /* push r */
                args_size += 8;
            }
        }
        vtop--;
    }
    vtop = orig_vtop;

    /* then, we prepare register passing arguments.
       Note that we cannot set RDX and RCX in this loop because gv()
       may break these temporary registers. Let's use R10 and R11
       instead of them */
    gen_reg = nb_reg_args;
    sse_reg = nb_sse_args;
    for(i = 0; i < nb_args; i++) {
        if ((vtop->type.t & VT_BTYPE) == VT_STRUCT ||
            (vtop->type.t & VT_BTYPE) == VT_LDOUBLE) {
        } else if (is_sse_float(vtop->type.t)) {
            int j = --sse_reg;
            if (j < 8) {
                gv(RC_FLOAT); /* only one float register */
                /* movaps %xmm0, %xmmN */
                o(0x280f);
                o(0xc0 + (sse_reg << 3));
            }
        } else {
            int j = --gen_reg;
            /* simple type */
            /* XXX: implicit cast ? */
            if (j < 6) {
                r = gv(RC_INT);
                if (j < 2) {
                    o(0x8948); /* mov */
                    o(0xc0 + r * 8 + arg_regs[j]);
                } else if (j < 4) {
                    o(0x8949); /* mov */
                    /* j=2: r10, j=3: r11 */
                    o(0xc0 + r * 8 + j);
                } else {
                    o(0x8949); /* mov */
                    /* j=4: r8, j=5: r9 */
                    o(0xc0 + r * 8 + j - 4);
                }
            }
        }
        vtop--;
    }

    save_regs(0); /* save used temporary registers */

    /* Copy R10 and R11 into RDX and RCX, respectively */
    if (nb_reg_args > 2) {
        o(0xd2894c); /* mov %r10, %rdx */
        if (nb_reg_args > 3) {
            o(0xd9894c); /* mov %r11, %rcx */
        }
    }

    func_sym = vtop->type.ref;
    func_call = FUNC_CALL(func_sym->r);
    oad(0xb8, nb_sse_args < 8 ? nb_sse_args : 8); /* mov nb_sse_args, %eax */
    gcall_or_jmp(0);
    if (args_size)
        gadd_sp(args_size);
    vtop--;
}

#ifdef TCC_TARGET_PE
/* XXX: support PE? */
#warning "PE isn't tested at all"
#define FUNC_PROLOG_SIZE 12
#else
#define FUNC_PROLOG_SIZE 11
#endif

static void push_arg_reg(int i) {
    loc -= 8;
    gen_modrm64(0x89, arg_regs[i], VT_LOCAL, NULL, loc);
}

/* generate function prolog of type 't' */
void gfunc_prolog(CType *func_type)
{
    int i, addr, align, size, func_call;
    int param_index, param_addr, reg_param_index, sse_param_index;
    Sym *sym;
    CType *type;

    func_ret_sub = 0;

    sym = func_type->ref;
    func_call = FUNC_CALL(sym->r);
    addr = PTR_SIZE * 2;
    loc = 0;
    ind += FUNC_PROLOG_SIZE;
    func_sub_sp_offset = ind;

    if (func_type->ref->c == FUNC_ELLIPSIS) {
        int seen_reg_num, seen_sse_num, seen_stack_size;
        seen_reg_num = seen_sse_num = 0;
        /* frame pointer and return address */
        seen_stack_size = PTR_SIZE * 2;
        /* count the number of seen parameters */
        sym = func_type->ref;
        while ((sym = sym->next) != NULL) {
            type = &sym->type;
            if (is_sse_float(type->t)) {
                if (seen_sse_num < 8) {
                    seen_sse_num++;
                } else {
                    seen_stack_size += 8;
                }
            } else if ((type->t & VT_BTYPE) == VT_STRUCT) {
                size = type_size(type, &align);
                size = (size + 3) & ~3;
                seen_stack_size += size;
            } else if ((type->t & VT_BTYPE) == VT_LDOUBLE) {
                seen_stack_size += LDOUBLE_SIZE;
            } else {
                if (seen_reg_num < 6) {
                    seen_reg_num++;
                } else {
                    seen_stack_size += 8;
                }
            }
        }

        loc -= 16;
        /* movl $0x????????, -0x10(%rbp) */
        o(0xf045c7);
        gen_le32(seen_reg_num * 8);
        /* movl $0x????????, -0xc(%rbp) */
        o(0xf445c7);
        gen_le32(seen_sse_num * 16 + 48);
        /* movl $0x????????, -0x8(%rbp) */
        o(0xf845c7);
        gen_le32(seen_stack_size);

        /* save all register passing arguments */
        for (i = 0; i < 8; i++) {
            loc -= 16;
            o(0xd60f66); /* movq */
            gen_modrm(7 - i, VT_LOCAL, NULL, loc);
            /* movq $0, loc+8(%rbp) */
            o(0x85c748);
            gen_le32(loc + 8);
            gen_le32(0);
        }
        for (i = 0; i < 6; i++) {
            push_arg_reg(5 - i);
        }
    }

    sym = func_type->ref;
    param_index = 0;
    reg_param_index = 0;
    sse_param_index = 0;

    /* if the function returns a structure, then add an
       implicit pointer parameter */
    func_vt = sym->type;
    if ((func_vt.t & VT_BTYPE) == VT_STRUCT) {
        push_arg_reg(reg_param_index);
        param_addr = loc;

        func_vc = loc;
        param_index++;
        reg_param_index++;
    }
    /* define parameters */
    while ((sym = sym->next) != NULL) {
        type = &sym->type;
        size = type_size(type, &align);
        size = (size + 3) & ~3;
        if (is_sse_float(type->t)) {
            if (sse_param_index < 8) {
                /* save arguments passed by register */
                loc -= 8;
                o(0xd60f66); /* movq */
                gen_modrm(sse_param_index, VT_LOCAL, NULL, loc);
                param_addr = loc;
            } else {
                param_addr = addr;
                addr += size;
            }
            sse_param_index++;
        } else if ((type->t & VT_BTYPE) == VT_STRUCT ||
                   (type->t & VT_BTYPE) == VT_LDOUBLE) {
            param_addr = addr;
            addr += size;
        } else {
            if (reg_param_index < 6) {
                /* save arguments passed by register */
                push_arg_reg(reg_param_index);
                param_addr = loc;
            } else {
                param_addr = addr;
                addr += 8;
            }
            reg_param_index++;
        }
        sym_push(sym->v & ~SYM_FIELD, type,
                 VT_LOCAL | VT_LVAL, param_addr);
        param_index++;
    }
}

/* generate function epilog */
void gfunc_epilog(void)
{
    int v, saved_ind;

    o(0xc9); /* leave */
    if (func_ret_sub == 0) {
        o(0xc3); /* ret */
    } else {
        o(0xc2); /* ret n */
        g(func_ret_sub);
        g(func_ret_sub >> 8);
    }
    /* align local size to word & save local variables */
    v = (-loc + 15) & -16;
    saved_ind = ind;
    ind = func_sub_sp_offset - FUNC_PROLOG_SIZE;
#ifdef TCC_TARGET_PE
    if (v >= 4096) {
        Sym *sym = external_global_sym(TOK___chkstk, &func_old_type, 0);
        oad(0xb8, v); /* mov stacksize, %eax */
        oad(0xe8, -4); /* call __chkstk, (does the stackframe too) */
        greloc(cur_text_section, sym, ind-4, R_X86_64_PC32);
    } else
#endif
    {
        o(0xe5894855);  /* push %rbp, mov %rsp, %rbp */
        o(0xec8148);  /* sub rsp, stacksize */
        gen_le32(v);
#if FUNC_PROLOG_SIZE == 12
        o(0x90);  /* adjust to FUNC_PROLOG_SIZE */
#endif
    }
    ind = saved_ind;
}

/* generate a jump to a label */
int gjmp(int t)
{
    return psym(0xe9, t);
}

/* generate a jump to a fixed address */
void gjmp_addr(int a)
{
    int r;
    r = a - ind - 2;
    if (r == (char)r) {
        g(0xeb);
        g(r);
    } else {
        oad(0xe9, a - ind - 5);
    }
}

/* generate a test. set 'inv' to invert test. Stack entry is popped */
int gtst(int inv, int t)
{
    int v, *p;

    v = vtop->r & VT_VALMASK;
    if (v == VT_CMP) {
        /* fast case : can jump directly since flags are set */
        g(0x0f);
        t = psym((vtop->c.i - 16) ^ inv, t);
    } else if (v == VT_JMP || v == VT_JMPI) {
        /* && or || optimization */
        if ((v & 1) == inv) {
            /* insert vtop->c jump list in t */
            p = &vtop->c.i;
            while (*p != 0)
                p = (int *)(cur_text_section->data + *p);
            *p = t;
            t = vtop->c.i;
        } else {
            t = gjmp(t);
            gsym(vtop->c.i);
        }
    } else {
        if (is_float(vtop->type.t) ||
            (vtop->type.t & VT_BTYPE) == VT_LLONG) {
            vpushi(0);
            gen_op(TOK_NE);
        }
        if ((vtop->r & (VT_VALMASK | VT_LVAL | VT_SYM)) == VT_CONST) {
            /* constant jmp optimization */
            if ((vtop->c.i != 0) != inv)
                t = gjmp(t);
        } else {
            v = gv(RC_INT);
            o(0x85);
            o(0xc0 + v * 9);
            g(0x0f);
            t = psym(0x85 ^ inv, t);
        }
    }
    vtop--;
    return t;
}

/* generate an integer binary operation */
void gen_opi(int op)
{
    int r, fr, opc, c;

    switch(op) {
    case '+':
    case TOK_ADDC1: /* add with carry generation */
        opc = 0;
    gen_op8:
        if ((vtop->r & (VT_VALMASK | VT_LVAL | VT_SYM)) == VT_CONST &&
            !is64_type(vtop->type.t)) {
            /* constant case */
            vswap();
            r = gv(RC_INT);
            if (is64_type(vtop->type.t)) {
                o(0x48 | REX_BASE(r));
            }
            vswap();
            c = vtop->c.i;
            if (c == (char)c) {
                /* XXX: generate inc and dec for smaller code ? */
                o(0x83);
                o(0xc0 | (opc << 3) | REG_VALUE(r));
                g(c);
            } else {
                o(0x81);
                oad(0xc0 | (opc << 3) | REG_VALUE(r), c);
            }
        } else {
            gv2(RC_INT, RC_INT);
            r = vtop[-1].r;
            fr = vtop[0].r;
            if (opc != 7 ||
                is64_type(vtop[0].type.t) || (vtop[0].type.t & VT_UNSIGNED) ||
                is64_type(vtop[-1].type.t) || (vtop[-1].type.t & VT_UNSIGNED)) {
                o(0x48 | REX_BASE(r) | (REX_BASE(fr) << 2));
            }
            o((opc << 3) | 0x01);
            o(0xc0 + REG_VALUE(r) + REG_VALUE(fr) * 8);
        }
        vtop--;
        if (op >= TOK_ULT && op <= TOK_GT) {
            vtop->r = VT_CMP;
            vtop->c.i = op;
        }
        break;
    case '-':
    case TOK_SUBC1: /* sub with carry generation */
        opc = 5;
        goto gen_op8;
    case TOK_ADDC2: /* add with carry use */
        opc = 2;
        goto gen_op8;
    case TOK_SUBC2: /* sub with carry use */
        opc = 3;
        goto gen_op8;
    case '&':
        opc = 4;
        goto gen_op8;
    case '^':
        opc = 6;
        goto gen_op8;
    case '|':
        opc = 1;
        goto gen_op8;
    case '*':
        gv2(RC_INT, RC_INT);
        r = vtop[-1].r;
        fr = vtop[0].r;
        if (is64_type(vtop[0].type.t) || (vtop[0].type.t & VT_UNSIGNED) ||
            is64_type(vtop[-1].type.t) || (vtop[-1].type.t & VT_UNSIGNED)) {
            o(0x48 | REX_BASE(fr) | (REX_BASE(r) << 2));
        }
        vtop--;
        o(0xaf0f); /* imul fr, r */
        o(0xc0 + fr + r * 8);
        break;
    case TOK_SHL:
        opc = 4;
        goto gen_shift;
    case TOK_SHR:
        opc = 5;
        goto gen_shift;
    case TOK_SAR:
        opc = 7;
    gen_shift:
        opc = 0xc0 | (opc << 3);
        if ((vtop->r & (VT_VALMASK | VT_LVAL | VT_SYM)) == VT_CONST) {
            /* constant case */
            vswap();
            r = gv(RC_INT);
            if ((vtop->type.t & VT_BTYPE) == VT_LLONG) {
                o(0x48 | REX_BASE(r));
                c = 0x3f;
            } else {
                c = 0x1f;
            }
            vswap();
            c &= vtop->c.i;
            o(0xc1); /* shl/shr/sar $xxx, r */
            o(opc | r);
            g(c);
        } else {
            /* we generate the shift in ecx */
            gv2(RC_INT, RC_RCX);
            r = vtop[-1].r;
            if ((vtop[-1].type.t & VT_BTYPE) == VT_LLONG) {
                o(0x48 | REX_BASE(r));
            }
            o(0xd3); /* shl/shr/sar %cl, r */
            o(opc | r);
        }
        vtop--;
        break;
    case '/':
    case TOK_UDIV:
    case TOK_PDIV:
    case '%':
    case TOK_UMOD:
    case TOK_UMULL:
        /* first operand must be in eax */
        /* XXX: need better constraint for second operand */
        gv2(RC_RAX, RC_RCX);
        r = vtop[-1].r;
        fr = vtop[0].r;
        vtop--;
        save_reg(TREG_RDX);
        if (op == TOK_UMULL) {
            o(0xf7); /* mul fr */
            o(0xe0 + fr);
            vtop->r2 = TREG_RDX;
            r = TREG_RAX;
        } else {
            if (op == TOK_UDIV || op == TOK_UMOD) {
                o(0xf7d231); /* xor %edx, %edx, div fr, %eax */
                o(0xf0 + fr);
            } else {
                if ((vtop->type.t & VT_BTYPE) & VT_LLONG) {
                    o(0x9948); /* cqto */
                    o(0x48 + REX_BASE(fr));
                } else {
                    o(0x99); /* cltd */
                }
                o(0xf7); /* idiv fr, %eax */
                o(0xf8 + fr);
            }
            if (op == '%' || op == TOK_UMOD)
                r = TREG_RDX;
            else
                r = TREG_RAX;
        }
        vtop->r = r;
        break;
    default:
        opc = 7;
        goto gen_op8;
    }
}

void gen_opl(int op)
{
    gen_opi(op);
}

/* generate a floating point operation 'v = t1 op t2' instruction. The
   two operands are guaranted to have the same floating point type */
/* XXX: need to use ST1 too */
void gen_opf(int op)
{
    int a, ft, fc, swapped, r;
    int float_type =
        (vtop->type.t & VT_BTYPE) == VT_LDOUBLE ? RC_ST0 : RC_FLOAT;

    /* convert constants to memory references */
    if ((vtop[-1].r & (VT_VALMASK | VT_LVAL)) == VT_CONST) {
        vswap();
        gv(float_type);
        vswap();
    }
    if ((vtop[0].r & (VT_VALMASK | VT_LVAL)) == VT_CONST)
        gv(float_type);

    /* must put at least one value in the floating point register */
    if ((vtop[-1].r & VT_LVAL) &&
        (vtop[0].r & VT_LVAL)) {
        vswap();
        gv(float_type);
        vswap();
    }
    swapped = 0;
    /* swap the stack if needed so that t1 is the register and t2 is
       the memory reference */
    if (vtop[-1].r & VT_LVAL) {
        vswap();
        swapped = 1;
    }
    if ((vtop->type.t & VT_BTYPE) == VT_LDOUBLE) {
        if (op >= TOK_ULT && op <= TOK_GT) {
            /* load on stack second operand */
            load(TREG_ST0, vtop);
            save_reg(TREG_RAX); /* eax is used by FP comparison code */
            if (op == TOK_GE || op == TOK_GT)
                swapped = !swapped;
            else if (op == TOK_EQ || op == TOK_NE)
                swapped = 0;
            if (swapped)
                o(0xc9d9); /* fxch %st(1) */
            o(0xe9da); /* fucompp */
            o(0xe0df); /* fnstsw %ax */
            if (op == TOK_EQ) {
                o(0x45e480); /* and $0x45, %ah */
                o(0x40fC80); /* cmp $0x40, %ah */
            } else if (op == TOK_NE) {
                o(0x45e480); /* and $0x45, %ah */
                o(0x40f480); /* xor $0x40, %ah */
                op = TOK_NE;
            } else if (op == TOK_GE || op == TOK_LE) {
                o(0x05c4f6); /* test $0x05, %ah */
                op = TOK_EQ;
            } else {
                o(0x45c4f6); /* test $0x45, %ah */
                op = TOK_EQ;
            }
            vtop--;
            vtop->r = VT_CMP;
            vtop->c.i = op;
        } else {
            /* no memory reference possible for long double operations */
            load(TREG_ST0, vtop);
            swapped = !swapped;

            switch(op) {
            default:
            case '+':
                a = 0;
                break;
            case '-':
                a = 4;
                if (swapped)
                    a++;
                break;
            case '*':
                a = 1;
                break;
            case '/':
                a = 6;
                if (swapped)
                    a++;
                break;
            }
            ft = vtop->type.t;
            fc = vtop->c.ul;
            o(0xde); /* fxxxp %st, %st(1) */
            o(0xc1 + (a << 3));
            vtop--;
        }
    } else {
        if (op >= TOK_ULT && op <= TOK_GT) {
            /* if saved lvalue, then we must reload it */
            r = vtop->r;
            fc = vtop->c.ul;
            if ((r & VT_VALMASK) == VT_LLOCAL) {
                SValue v1;
                r = get_reg(RC_INT);
                v1.type.t = VT_INT;
                v1.r = VT_LOCAL | VT_LVAL;
                v1.c.ul = fc;
                load(r, &v1);
                fc = 0;
            }

            if (op == TOK_EQ || op == TOK_NE) {
                swapped = 0;
            } else {
                if (op == TOK_LE || op == TOK_LT)
                    swapped = !swapped;
                if (op == TOK_LE || op == TOK_GE) {
                    op = 0x93; /* setae */
                } else {
                    op = 0x97; /* seta */
                }
            }

            if (swapped) {
                o(0x7e0ff3); /* movq */
                gen_modrm(1, r, vtop->sym, fc);

                if ((vtop->type.t & VT_BTYPE) == VT_DOUBLE) {
                    o(0x66);
                }
                o(0x2e0f); /* ucomisd %xmm0, %xmm1 */
                o(0xc8);
            } else {
                if ((vtop->type.t & VT_BTYPE) == VT_DOUBLE) {
                    o(0x66);
                }
                o(0x2e0f); /* ucomisd */
                gen_modrm(0, r, vtop->sym, fc);
            }

            vtop--;
            vtop->r = VT_CMP;
            vtop->c.i = op;
        } else {
            /* no memory reference possible for long double operations */
            if ((vtop->type.t & VT_BTYPE) == VT_LDOUBLE) {
                load(TREG_XMM0, vtop);
                swapped = !swapped;
            }
            switch(op) {
            default:
            case '+':
                a = 0;
                break;
            case '-':
                a = 4;
                break;
            case '*':
                a = 1;
                break;
            case '/':
                a = 6;
                break;
            }
            ft = vtop->type.t;
            fc = vtop->c.ul;
            if ((ft & VT_BTYPE) == VT_LDOUBLE) {
                o(0xde); /* fxxxp %st, %st(1) */
                o(0xc1 + (a << 3));
            } else {
                /* if saved lvalue, then we must reload it */
                r = vtop->r;
                if ((r & VT_VALMASK) == VT_LLOCAL) {
                    SValue v1;
                    r = get_reg(RC_INT);
                    v1.type.t = VT_INT;
                    v1.r = VT_LOCAL | VT_LVAL;
                    v1.c.ul = fc;
                    load(r, &v1);
                    fc = 0;
                }
                if (swapped) {
                    /* movq %xmm0,%xmm1 */
                    o(0x7e0ff3);
                    o(0xc8);
                    load(TREG_XMM0, vtop);
                    /* subsd  %xmm1,%xmm0 (f2 0f 5c c1) */
                    if ((ft & VT_BTYPE) == VT_DOUBLE) {
                        o(0xf2);
                    } else {
                        o(0xf3);
                    }
                    o(0x0f);
                    o(0x58 + a);
                    o(0xc1);
                } else {
                    if ((ft & VT_BTYPE) == VT_DOUBLE) {
                        o(0xf2);
                    } else {
                        o(0xf3);
                    }
                    o(0x0f);
                    o(0x58 + a);
                    gen_modrm(0, r, vtop->sym, fc);
                }
            }
            vtop--;
        }
    }
}

/* convert integers to fp 't' type. Must handle 'int', 'unsigned int'
   and 'long long' cases. */
void gen_cvt_itof(int t)
{
    if ((t & VT_BTYPE) == VT_LDOUBLE) {
        save_reg(TREG_ST0);
        gv(RC_INT);
        if ((vtop->type.t & VT_BTYPE) == VT_LLONG) {
            /* signed long long to float/double/long double (unsigned case
               is handled generically) */
            o(0x50 + (vtop->r & VT_VALMASK)); /* push r */
            o(0x242cdf); /* fildll (%rsp) */
            o(0x08c48348); /* add $8, %rsp */
        } else if ((vtop->type.t & (VT_BTYPE | VT_UNSIGNED)) ==
                   (VT_INT | VT_UNSIGNED)) {
            /* unsigned int to float/double/long double */
            o(0x6a); /* push $0 */
            g(0x00);
            o(0x50 + (vtop->r & VT_VALMASK)); /* push r */
            o(0x242cdf); /* fildll (%rsp) */
            o(0x10c48348); /* add $16, %rsp */
        } else {
            /* int to float/double/long double */
            o(0x50 + (vtop->r & VT_VALMASK)); /* push r */
            o(0x2404db); /* fildl (%rsp) */
            o(0x08c48348); /* add $8, %rsp */
        }
        vtop->r = TREG_ST0;
    } else {
        save_reg(TREG_XMM0);
        gv(RC_INT);
        o(0xf2 + ((t & VT_BTYPE) == VT_FLOAT));
        if ((vtop->type.t & (VT_BTYPE | VT_UNSIGNED)) ==
            (VT_INT | VT_UNSIGNED) ||
            (vtop->type.t & VT_BTYPE) == VT_LLONG) {
            o(0x48); /* REX */
        }
        o(0x2a0f);
        o(0xc0 + (vtop->r & VT_VALMASK)); /* cvtsi2sd */
        vtop->r = TREG_XMM0;
    }
}

/* convert from one floating point type to another */
void gen_cvt_ftof(int t)
{
    int ft, bt, tbt;

    ft = vtop->type.t;
    bt = ft & VT_BTYPE;
    tbt = t & VT_BTYPE;

    if (bt == VT_FLOAT) {
        gv(RC_FLOAT);
        if (tbt == VT_DOUBLE) {
            o(0xc0140f); /* unpcklps */
            o(0xc05a0f); /* cvtps2pd */
        } else if (tbt == VT_LDOUBLE) {
            /* movss %xmm0,-0x10(%rsp) */
            o(0x44110ff3);
            o(0xf024);
            o(0xf02444d9); /* flds -0x10(%rsp) */
            vtop->r = TREG_ST0;
        }
    } else if (bt == VT_DOUBLE) {
        gv(RC_FLOAT);
        if (tbt == VT_FLOAT) {
            o(0xc0140f66); /* unpcklpd */
            o(0xc05a0f66); /* cvtpd2ps */
        } else if (tbt == VT_LDOUBLE) {
            /* movsd %xmm0,-0x10(%rsp) */
            o(0x44110ff2);
            o(0xf024);
            o(0xf02444dd); /* fldl -0x10(%rsp) */
            vtop->r = TREG_ST0;
        }
    } else {
        gv(RC_ST0);
        if (tbt == VT_DOUBLE) {
            o(0xf0245cdd); /* fstpl -0x10(%rsp) */
            /* movsd -0x10(%rsp),%xmm0 */
            o(0x44100ff2);
            o(0xf024);
            vtop->r = TREG_XMM0;
        } else if (tbt == VT_FLOAT) {
            o(0xf0245cd9); /* fstps -0x10(%rsp) */
            /* movss -0x10(%rsp),%xmm0 */
            o(0x44100ff3);
            o(0xf024);
            vtop->r = TREG_XMM0;
        }
    }
}

/* convert fp to int 't' type */
void gen_cvt_ftoi(int t)
{
    int ft, bt, size, r;
    ft = vtop->type.t;
    bt = ft & VT_BTYPE;
    if (bt == VT_LDOUBLE) {
        gen_cvt_ftof(VT_DOUBLE);
        bt = VT_DOUBLE;
    }

    gv(RC_FLOAT);
    if (t != VT_INT)
        size = 8;
    else
        size = 4;

    r = get_reg(RC_INT);
    if (bt == VT_FLOAT) {
        o(0xf3);
    } else if (bt == VT_DOUBLE) {
        o(0xf2);
    } else {
        assert(0);
    }
    if (size == 8) {
        o(0x48 + REX_BASE(r));
    }
    o(0x2c0f); /* cvttss2si or cvttsd2si */
    o(0xc0 + (REG_VALUE(r) << 3));
    vtop->r = r;
}

/* computed goto support */
void ggoto(void)
{
    gcall_or_jmp(1);
    vtop--;
}

/* end of x86-64 code generator */
/*************************************************************/
