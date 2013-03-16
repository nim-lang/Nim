/*
 *  GAS like assembler for TCC
 * 
 *  Copyright (c) 2001-2004 Fabrice Bellard
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

static int asm_get_local_label_name(TCCState *s1, unsigned int n)
{
    char buf[64];
    TokenSym *ts;

    snprintf(buf, sizeof(buf), "L..%u", n);
    ts = tok_alloc(buf, strlen(buf));
    return ts->tok;
}

static void asm_expr(TCCState *s1, ExprValue *pe);

/* We do not use the C expression parser to handle symbols. Maybe the
   C expression parser could be tweaked to do so. */

static void asm_expr_unary(TCCState *s1, ExprValue *pe)
{
    Sym *sym;
    int op, n, label;
    const char *p;

    switch(tok) {
    case TOK_PPNUM:
        p = tokc.cstr->data;
        n = strtoul(p, (char **)&p, 0);
        if (*p == 'b' || *p == 'f') {
            /* backward or forward label */
            label = asm_get_local_label_name(s1, n);
            sym = label_find(label);
            if (*p == 'b') {
                /* backward : find the last corresponding defined label */
                if (sym && sym->r == 0)
                    sym = sym->prev_tok;
                if (!sym)
                    error("local label '%d' not found backward", n);
            } else {
                /* forward */
                if (!sym || sym->r) {
                    /* if the last label is defined, then define a new one */
                    sym = label_push(&s1->asm_labels, label, 0);
                    sym->type.t = VT_STATIC | VT_VOID;
                }
            }
            pe->v = 0;
            pe->sym = sym;
        } else if (*p == '\0') {
            pe->v = n;
            pe->sym = NULL;
        } else {
            error("invalid number syntax");
        }
        next();
        break;
    case '+':
        next();
        asm_expr_unary(s1, pe);
        break;
    case '-':
    case '~':
        op = tok;
        next();
        asm_expr_unary(s1, pe);
        if (pe->sym)
            error("invalid operation with label");
        if (op == '-')
            pe->v = -pe->v;
        else
            pe->v = ~pe->v;
        break;
    case TOK_CCHAR:
    case TOK_LCHAR:
	pe->v = tokc.i;
	pe->sym = NULL;
	next();
	break;
    case '(':
        next();
        asm_expr(s1, pe);
        skip(')');
        break;
    default:
        if (tok >= TOK_IDENT) {
            /* label case : if the label was not found, add one */
            sym = label_find(tok);
            if (!sym) {
                sym = label_push(&s1->asm_labels, tok, 0);
                /* NOTE: by default, the symbol is global */
                sym->type.t = VT_VOID;
            }
            if (sym->r == SHN_ABS) {
                /* if absolute symbol, no need to put a symbol value */
                pe->v = (long)sym->next;
                pe->sym = NULL;
            } else {
                pe->v = 0;
                pe->sym = sym;
            }
            next();
        } else {
            error("bad expression syntax [%s]", get_tok_str(tok, &tokc));
        }
        break;
    }
}
    
static void asm_expr_prod(TCCState *s1, ExprValue *pe)
{
    int op;
    ExprValue e2;

    asm_expr_unary(s1, pe);
    for(;;) {
        op = tok;
        if (op != '*' && op != '/' && op != '%' && 
            op != TOK_SHL && op != TOK_SAR)
            break;
        next();
        asm_expr_unary(s1, &e2);
        if (pe->sym || e2.sym)
            error("invalid operation with label");
        switch(op) {
        case '*':
            pe->v *= e2.v;
            break;
        case '/':  
            if (e2.v == 0) {
            div_error:
                error("division by zero");
            }
            pe->v /= e2.v;
            break;
        case '%':  
            if (e2.v == 0)
                goto div_error;
            pe->v %= e2.v;
            break;
        case TOK_SHL:
            pe->v <<= e2.v;
            break;
        default:
        case TOK_SAR:
            pe->v >>= e2.v;
            break;
        }
    }
}

static void asm_expr_logic(TCCState *s1, ExprValue *pe)
{
    int op;
    ExprValue e2;

    asm_expr_prod(s1, pe);
    for(;;) {
        op = tok;
        if (op != '&' && op != '|' && op != '^')
            break;
        next();
        asm_expr_prod(s1, &e2);
        if (pe->sym || e2.sym)
            error("invalid operation with label");
        switch(op) {
        case '&':
            pe->v &= e2.v;
            break;
        case '|':  
            pe->v |= e2.v;
            break;
        default:
        case '^':
            pe->v ^= e2.v;
            break;
        }
    }
}

static inline void asm_expr_sum(TCCState *s1, ExprValue *pe)
{
    int op;
    ExprValue e2;

    asm_expr_logic(s1, pe);
    for(;;) {
        op = tok;
        if (op != '+' && op != '-')
            break;
        next();
        asm_expr_logic(s1, &e2);
        if (op == '+') {
            if (pe->sym != NULL && e2.sym != NULL)
                goto cannot_relocate;
            pe->v += e2.v;
            if (pe->sym == NULL && e2.sym != NULL)
                pe->sym = e2.sym;
        } else {
            pe->v -= e2.v;
            /* NOTE: we are less powerful than gas in that case
               because we store only one symbol in the expression */
            if (!pe->sym && !e2.sym) {
                /* OK */
            } else if (pe->sym && !e2.sym) {
                /* OK */
            } else if (pe->sym && e2.sym) {
                if (pe->sym == e2.sym) { 
                    /* OK */
                } else if (pe->sym->r == e2.sym->r && pe->sym->r != 0) {
                    /* we also accept defined symbols in the same section */
                    pe->v += (long)pe->sym->next - (long)e2.sym->next;
                } else {
                    goto cannot_relocate;
                }
                pe->sym = NULL; /* same symbols can be substracted to NULL */
            } else {
            cannot_relocate:
                error("invalid operation with label");
            }
        }
    }
}

static void asm_expr(TCCState *s1, ExprValue *pe)
{
    asm_expr_sum(s1, pe);
}

static int asm_int_expr(TCCState *s1)
{
    ExprValue e;
    asm_expr(s1, &e);
    if (e.sym)
        expect("constant");
    return e.v;
}

/* NOTE: the same name space as C labels is used to avoid using too
   much memory when storing labels in TokenStrings */
static void asm_new_label1(TCCState *s1, int label, int is_local,
                           int sh_num, int value)
{
    Sym *sym;

    sym = label_find(label);
    if (sym) {
        if (sym->r) {
            /* the label is already defined */
            if (!is_local) {
                error("assembler label '%s' already defined", 
                      get_tok_str(label, NULL));
            } else {
                /* redefinition of local labels is possible */
                goto new_label;
            }
        }
    } else {
    new_label:
        sym = label_push(&s1->asm_labels, label, 0);
        sym->type.t = VT_STATIC | VT_VOID;
    }
    sym->r = sh_num;
    sym->next = (void *)value;
}

static void asm_new_label(TCCState *s1, int label, int is_local)
{
    asm_new_label1(s1, label, is_local, cur_text_section->sh_num, ind);
}

static void asm_free_labels(TCCState *st)
{
    Sym *s, *s1;
    Section *sec;
    
    for(s = st->asm_labels; s != NULL; s = s1) {
        s1 = s->prev;
        /* define symbol value in object file */
        if (s->r) {
            if (s->r == SHN_ABS)
                sec = SECTION_ABS;
            else
                sec = st->sections[s->r];
            put_extern_sym2(s, sec, (long)s->next, 0, 0);
        }
        /* remove label */
        table_ident[s->v - TOK_IDENT]->sym_label = NULL;
        sym_free(s);
    }
    st->asm_labels = NULL;
}

static void use_section1(TCCState *s1, Section *sec)
{
    cur_text_section->data_offset = ind;
    cur_text_section = sec;
    ind = cur_text_section->data_offset;
}

static void use_section(TCCState *s1, const char *name)
{
    Section *sec;
    sec = find_section(s1, name);
    use_section1(s1, sec);
}

static void asm_parse_directive(TCCState *s1)
{
    int n, offset, v, size, tok1;
    Section *sec;
    uint8_t *ptr;

    /* assembler directive */
    next();
    sec = cur_text_section;
    switch(tok) {
    case TOK_ASM_align:
    case TOK_ASM_skip:
    case TOK_ASM_space:
        tok1 = tok;
        next();
        n = asm_int_expr(s1);
        if (tok1 == TOK_ASM_align) {
            if (n < 0 || (n & (n-1)) != 0)
                error("alignment must be a positive power of two");
            offset = (ind + n - 1) & -n;
            size = offset - ind;
            /* the section must have a compatible alignment */
            if (sec->sh_addralign < n)
                sec->sh_addralign = n;
        } else {
            size = n;
        }
        v = 0;
        if (tok == ',') {
            next();
            v = asm_int_expr(s1);
        }
    zero_pad:
        if (sec->sh_type != SHT_NOBITS) {
            sec->data_offset = ind;
            ptr = section_ptr_add(sec, size);
            memset(ptr, v, size);
        }
        ind += size;
        break;
    case TOK_ASM_quad:
        next();
        for(;;) {
            uint64_t vl;
            const char *p;

            p = tokc.cstr->data;
            if (tok != TOK_PPNUM) {
            error_constant:
                error("64 bit constant");
            }
            vl = strtoll(p, (char **)&p, 0);
            if (*p != '\0')
                goto error_constant;
            next();
            if (sec->sh_type != SHT_NOBITS) {
                /* XXX: endianness */
                gen_le32(vl);
                gen_le32(vl >> 32);
            } else {
                ind += 8;
            }
            if (tok != ',')
                break;
            next();
        }
        break;
    case TOK_ASM_byte:
        size = 1;
        goto asm_data;
    case TOK_ASM_word:
    case TOK_SHORT:
        size = 2;
        goto asm_data;
    case TOK_LONG:
    case TOK_INT:
        size = 4;
    asm_data:
        next();
        for(;;) {
            ExprValue e;
            asm_expr(s1, &e);
            if (sec->sh_type != SHT_NOBITS) {
                if (size == 4) {
                    gen_expr32(&e);
                } else {
                    if (e.sym)
                        expect("constant");
                    if (size == 1)
                        g(e.v);
                    else
                        gen_le16(e.v);
                }
            } else {
                ind += size;
            }
            if (tok != ',')
                break;
            next();
        }
        break;
    case TOK_ASM_fill:
        {
            int repeat, size, val, i, j;
            uint8_t repeat_buf[8];
            next();
            repeat = asm_int_expr(s1);
            if (repeat < 0) {
                error("repeat < 0; .fill ignored");
                break;
            }
            size = 1;
            val = 0;
            if (tok == ',') {
                next();
                size = asm_int_expr(s1);
                if (size < 0) {
                    error("size < 0; .fill ignored");
                    break;
                }
                if (size > 8)
                    size = 8;
                if (tok == ',') {
                    next();
                    val = asm_int_expr(s1);
                }
            }
            /* XXX: endianness */
            repeat_buf[0] = val;
            repeat_buf[1] = val >> 8;
            repeat_buf[2] = val >> 16;
            repeat_buf[3] = val >> 24;
            repeat_buf[4] = 0;
            repeat_buf[5] = 0;
            repeat_buf[6] = 0;
            repeat_buf[7] = 0;
            for(i = 0; i < repeat; i++) {
                for(j = 0; j < size; j++) {
                    g(repeat_buf[j]);
                }
            }
        }
        break;
    case TOK_ASM_org:
        {
            unsigned long n;
            next();
            /* XXX: handle section symbols too */
            n = asm_int_expr(s1);
            if (n < ind)
                error("attempt to .org backwards");
            v = 0;
            size = n - ind;
            goto zero_pad;
        }
        break;
    case TOK_ASM_globl:
    case TOK_ASM_global:
	{ 
            Sym *sym;

            next();
            sym = label_find(tok);
            if (!sym) {
                sym = label_push(&s1->asm_labels, tok, 0);
                sym->type.t = VT_VOID;
            }
            sym->type.t &= ~VT_STATIC;
            next();
	}
	break;
    case TOK_ASM_string:
    case TOK_ASM_ascii:
    case TOK_ASM_asciz:
        {
            const uint8_t *p;
            int i, size, t;

            t = tok;
            next();
            for(;;) {
                if (tok != TOK_STR)
                    expect("string constant");
                p = tokc.cstr->data;
                size = tokc.cstr->size;
                if (t == TOK_ASM_ascii && size > 0)
                    size--;
                for(i = 0; i < size; i++)
                    g(p[i]);
                next();
                if (tok == ',') {
                    next();
                } else if (tok != TOK_STR) {
                    break;
                }
            }
	}
	break;
    case TOK_ASM_text:
    case TOK_ASM_data:
    case TOK_ASM_bss:
	{ 
            char sname[64];
            tok1 = tok;
            n = 0;
            next();
            if (tok != ';' && tok != TOK_LINEFEED) {
		n = asm_int_expr(s1);
		next();
            }
            sprintf(sname, (n?".%s%d":".%s"), get_tok_str(tok1, NULL), n);
            use_section(s1, sname);
	}
	break;
    case TOK_SECTION1:
        {
            char sname[256];

            /* XXX: support more options */
            next();
            sname[0] = '\0';
            while (tok != ';' && tok != TOK_LINEFEED && tok != ',') {
                if (tok == TOK_STR)
                    pstrcat(sname, sizeof(sname), tokc.cstr->data);
                else
                    pstrcat(sname, sizeof(sname), get_tok_str(tok, NULL));
                next();
            }
            if (tok == ',') {
                /* skip section options */
                next();
                if (tok != TOK_STR)
                    expect("string constant");
                next();
            }
            last_text_section = cur_text_section;
            use_section(s1, sname);
        }
        break;
    case TOK_ASM_previous:
        { 
            Section *sec;
            next();
            if (!last_text_section)
                error("no previous section referenced");
            sec = cur_text_section;
            use_section1(s1, last_text_section);
            last_text_section = sec;
        }
        break;
    default:
        error("unknown assembler directive '.%s'", get_tok_str(tok, NULL));
        break;
    }
}


/* assemble a file */
static int tcc_assemble_internal(TCCState *s1, int do_preprocess)
{
    int opcode;

#if 0
    /* print stats about opcodes */
    {
        const ASMInstr *pa;
        int freq[4];
        int op_vals[500];
        int nb_op_vals, i, j;

        nb_op_vals = 0;
        memset(freq, 0, sizeof(freq));
        for(pa = asm_instrs; pa->sym != 0; pa++) {
            freq[pa->nb_ops]++;
            for(i=0;i<pa->nb_ops;i++) {
                for(j=0;j<nb_op_vals;j++) {
                    if (pa->op_type[i] == op_vals[j])
                        goto found;
                }
                op_vals[nb_op_vals++] = pa->op_type[i];
            found: ;
            }
        }
        for(i=0;i<nb_op_vals;i++) {
            int v = op_vals[i];
            if ((v & (v - 1)) != 0)
                printf("%3d: %08x\n", i, v);
        }
        printf("size=%d nb=%d f0=%d f1=%d f2=%d f3=%d\n",
               sizeof(asm_instrs), sizeof(asm_instrs) / sizeof(ASMInstr),
               freq[0], freq[1], freq[2], freq[3]);
    }
#endif

    /* XXX: undefine C labels */

    ch = file->buf_ptr[0];
    tok_flags = TOK_FLAG_BOL | TOK_FLAG_BOF;
    parse_flags = PARSE_FLAG_ASM_COMMENTS;
    if (do_preprocess)
        parse_flags |= PARSE_FLAG_PREPROCESS;
    next();
    for(;;) {
        if (tok == TOK_EOF)
            break;
        parse_flags |= PARSE_FLAG_LINEFEED; /* XXX: suppress that hack */
    redo:
        if (tok == '#') {
            /* horrible gas comment */
            while (tok != TOK_LINEFEED)
                next();
        } else if (tok == '.') {
            asm_parse_directive(s1);
        } else if (tok == TOK_PPNUM) {
            const char *p;
            int n;
            p = tokc.cstr->data;
            n = strtoul(p, (char **)&p, 10);
            if (*p != '\0')
                expect("':'");
            /* new local label */
            asm_new_label(s1, asm_get_local_label_name(s1, n), 1);
            next();
            skip(':');
            goto redo;
        } else if (tok >= TOK_IDENT) {
            /* instruction or label */
            opcode = tok;
            next();
            if (tok == ':') {
                /* new label */
                asm_new_label(s1, opcode, 0);
                next();
                goto redo;
            } else if (tok == '=') {
                int n;
                next();
                n = asm_int_expr(s1);
                asm_new_label1(s1, opcode, 0, SHN_ABS, n);
                goto redo;
            } else {
                asm_opcode(s1, opcode);
            }
        }
        /* end of line */
        if (tok != ';' && tok != TOK_LINEFEED){
            expect("end of line");
        }
        parse_flags &= ~PARSE_FLAG_LINEFEED; /* XXX: suppress that hack */
        next();
    }

    asm_free_labels(s1);

    return 0;
}

/* Assemble the current file */
static int tcc_assemble(TCCState *s1, int do_preprocess)
{
    Sym *define_start;
    int ret;

    preprocess_init(s1);

    /* default section is text */
    cur_text_section = text_section;
    ind = cur_text_section->data_offset;

    define_start = define_stack;

    ret = tcc_assemble_internal(s1, do_preprocess);

    cur_text_section->data_offset = ind;

    free_defines(define_start); 

    return ret;
}

/********************************************************************/
/* GCC inline asm support */

/* assemble the string 'str' in the current C compilation unit without
   C preprocessing. NOTE: str is modified by modifying the '\0' at the
   end */
static void tcc_assemble_inline(TCCState *s1, char *str, int len)
{
    BufferedFile *bf, *saved_file;
    int saved_parse_flags, *saved_macro_ptr;

    bf = tcc_malloc(sizeof(BufferedFile));
    memset(bf, 0, sizeof(BufferedFile));
    bf->fd = -1;
    bf->buf_ptr = str;
    bf->buf_end = str + len;
    str[len] = CH_EOB;
    /* same name as current file so that errors are correctly
       reported */
    pstrcpy(bf->filename, sizeof(bf->filename), file->filename);
    bf->line_num = file->line_num;
    saved_file = file;
    file = bf;
    saved_parse_flags = parse_flags;
    saved_macro_ptr = macro_ptr;
    macro_ptr = NULL;
    
    tcc_assemble_internal(s1, 0);

    parse_flags = saved_parse_flags;
    macro_ptr = saved_macro_ptr;
    file = saved_file;
    tcc_free(bf);
}

/* find a constraint by its number or id (gcc 3 extended
   syntax). return -1 if not found. Return in *pp in char after the
   constraint */
static int find_constraint(ASMOperand *operands, int nb_operands, 
                           const char *name, const char **pp)
{
    int index;
    TokenSym *ts;
    const char *p;

    if (isnum(*name)) {
        index = 0;
        while (isnum(*name)) {
            index = (index * 10) + (*name) - '0';
            name++;
        }
        if ((unsigned)index >= nb_operands)
            index = -1;
    } else if (*name == '[') {
        name++;
        p = strchr(name, ']');
        if (p) {
            ts = tok_alloc(name, p - name);
            for(index = 0; index < nb_operands; index++) {
                if (operands[index].id == ts->tok)
                    goto found;
            }
            index = -1;
        found:
            name = p + 1;
        } else {
            index = -1;
        }
    } else {
        index = -1;
    }
    if (pp)
        *pp = name;
    return index;
}

static void subst_asm_operands(ASMOperand *operands, int nb_operands, 
                               int nb_outputs,
                               CString *out_str, CString *in_str)
{
    int c, index, modifier;
    const char *str;
    ASMOperand *op;
    SValue sv;

    cstr_new(out_str);
    str = in_str->data;
    for(;;) {
        c = *str++;
        if (c == '%') {
            if (*str == '%') {
                str++;
                goto add_char;
            }
            modifier = 0;
            if (*str == 'c' || *str == 'n' ||
                *str == 'b' || *str == 'w' || *str == 'h')
                modifier = *str++;
            index = find_constraint(operands, nb_operands, str, &str);
            if (index < 0)
                error("invalid operand reference after %%");
            op = &operands[index];
            sv = *op->vt;
            if (op->reg >= 0) {
                sv.r = op->reg;
                if ((op->vt->r & VT_VALMASK) == VT_LLOCAL && op->is_memory)
                    sv.r |= VT_LVAL;
            }
            subst_asm_operand(out_str, &sv, modifier);
        } else {
        add_char:
            cstr_ccat(out_str, c);
            if (c == '\0')
                break;
        }
    }
}


static void parse_asm_operands(ASMOperand *operands, int *nb_operands_ptr,
                               int is_output)
{
    ASMOperand *op;
    int nb_operands;

    if (tok != ':') {
        nb_operands = *nb_operands_ptr;
        for(;;) {
            if (nb_operands >= MAX_ASM_OPERANDS)
                error("too many asm operands");
            op = &operands[nb_operands++];
            op->id = 0;
            if (tok == '[') {
                next();
                if (tok < TOK_IDENT)
                    expect("identifier");
                op->id = tok;
                next();
                skip(']');
            }
            if (tok != TOK_STR)
                expect("string constant");
            op->constraint = tcc_malloc(tokc.cstr->size);
            strcpy(op->constraint, tokc.cstr->data);
            next();
            skip('(');
            gexpr();
            if (is_output) {
                test_lvalue();
            } else {
                /* we want to avoid LLOCAL case, except when the 'm'
                   constraint is used. Note that it may come from
                   register storage, so we need to convert (reg)
                   case */
                if ((vtop->r & VT_LVAL) &&
                    ((vtop->r & VT_VALMASK) == VT_LLOCAL ||
                     (vtop->r & VT_VALMASK) < VT_CONST) &&
                    !strchr(op->constraint, 'm')) {
                    gv(RC_INT);
                }
            }
            op->vt = vtop;
            skip(')');
            if (tok == ',') {
                next();
            } else {
                break;
            }
        }
        *nb_operands_ptr = nb_operands;
    }
}

static void parse_asm_str(CString *astr)
{
    skip('(');
    /* read the string */
    if (tok != TOK_STR)
        expect("string constant");
    cstr_new(astr);
    while (tok == TOK_STR) {
        /* XXX: add \0 handling too ? */
        cstr_cat(astr, tokc.cstr->data);
        next();
    }
    cstr_ccat(astr, '\0');
}

/* parse the GCC asm() instruction */
static void asm_instr(void)
{
    CString astr, astr1;
    ASMOperand operands[MAX_ASM_OPERANDS];
    int nb_inputs, nb_outputs, nb_operands, i, must_subst, out_reg;
    uint8_t clobber_regs[NB_ASM_REGS];

    next();
    /* since we always generate the asm() instruction, we can ignore
       volatile */
    if (tok == TOK_VOLATILE1 || tok == TOK_VOLATILE2 || tok == TOK_VOLATILE3) {
        next();
    }
    parse_asm_str(&astr);
    nb_operands = 0;
    nb_outputs = 0;
    must_subst = 0;
    memset(clobber_regs, 0, sizeof(clobber_regs));
    if (tok == ':') {
        next();
        must_subst = 1;
        /* output args */
        parse_asm_operands(operands, &nb_operands, 1);
        nb_outputs = nb_operands;
        if (tok == ':') {
            next();
            if (tok != ')') {
                /* input args */
                parse_asm_operands(operands, &nb_operands, 0);
                if (tok == ':') {
                    /* clobber list */
                    /* XXX: handle registers */
                    next();
                    for(;;) {
                        if (tok != TOK_STR)
                            expect("string constant");
                        asm_clobber(clobber_regs, tokc.cstr->data);
                        next();
                        if (tok == ',') {
                            next();
                        } else {
                            break;
                        }
                    }
                }
            }
        }
    }
    skip(')');
    /* NOTE: we do not eat the ';' so that we can restore the current
       token after the assembler parsing */
    if (tok != ';')
        expect("';'");
    nb_inputs = nb_operands - nb_outputs;
    
    /* save all values in the memory */
    save_regs(0);

    /* compute constraints */
    asm_compute_constraints(operands, nb_operands, nb_outputs, 
                            clobber_regs, &out_reg);

    /* substitute the operands in the asm string. No substitution is
       done if no operands (GCC behaviour) */
#ifdef ASM_DEBUG
    printf("asm: \"%s\"\n", (char *)astr.data);
#endif
    if (must_subst) {
        subst_asm_operands(operands, nb_operands, nb_outputs, &astr1, &astr);
        cstr_free(&astr);
    } else {
        astr1 = astr;
    }
#ifdef ASM_DEBUG
    printf("subst_asm: \"%s\"\n", (char *)astr1.data);
#endif

    /* generate loads */
    asm_gen_code(operands, nb_operands, nb_outputs, 0, 
                 clobber_regs, out_reg);    

    /* assemble the string with tcc internal assembler */
    tcc_assemble_inline(tcc_state, astr1.data, astr1.size - 1);

    /* restore the current C token */
    next();

    /* store the output values if needed */
    asm_gen_code(operands, nb_operands, nb_outputs, 1, 
                 clobber_regs, out_reg);
    
    /* free everything */
    for(i=0;i<nb_operands;i++) {
        ASMOperand *op;
        op = &operands[i];
        tcc_free(op->constraint);
        vpop();
    }
    cstr_free(&astr1);
}

static void asm_global_instr(void)
{
    CString astr;

    next();
    parse_asm_str(&astr);
    skip(')');
    /* NOTE: we do not eat the ';' so that we can restore the current
       token after the assembler parsing */
    if (tok != ';')
        expect("';'");
    
#ifdef ASM_DEBUG
    printf("asm_global: \"%s\"\n", (char *)astr.data);
#endif
    cur_text_section = text_section;
    ind = cur_text_section->data_offset;

    /* assemble the string with tcc internal assembler */
    tcc_assemble_inline(tcc_state, astr.data, astr.size - 1);
    
    cur_text_section->data_offset = ind;

    /* restore the current C token */
    next();

    cstr_free(&astr);
}
