/*
 *  ARMv4 code generator for TCC
 * 
 *  Copyright (c) 2003 Daniel Glöckner
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

#ifdef TCC_ARM_EABI
#define TCC_ARM_VFP
#endif


/* number of available registers */
#ifdef TCC_ARM_VFP
#define NB_REGS            13
#else
#define NB_REGS             9
#endif

/* a register can belong to several classes. The classes must be
   sorted from more general to more precise (see gv2() code which does
   assumptions on it). */
#define RC_INT     0x0001 /* generic integer register */
#define RC_FLOAT   0x0002 /* generic float register */
#define RC_R0      0x0004
#define RC_R1      0x0008 
#define RC_R2      0x0010
#define RC_R3      0x0020
#define RC_R12     0x0040
#define RC_F0      0x0080
#define RC_F1      0x0100
#define RC_F2      0x0200
#define RC_F3      0x0400
#ifdef TCC_ARM_VFP
#define RC_F4      0x0800
#define RC_F5      0x1000
#define RC_F6      0x2000
#define RC_F7      0x4000
#endif
#define RC_IRET    RC_R0  /* function return: integer register */
#define RC_LRET    RC_R1  /* function return: second integer register */
#define RC_FRET    RC_F0  /* function return: float register */

/* pretty names for the registers */
enum {
    TREG_R0 = 0,
    TREG_R1,
    TREG_R2,
    TREG_R3,
    TREG_R12,
    TREG_F0,
    TREG_F1,
    TREG_F2,
    TREG_F3,
#ifdef TCC_ARM_VFP
    TREG_F4,
    TREG_F5,
    TREG_F6,
    TREG_F7,
#endif
};

int reg_classes[NB_REGS] = {
    /* r0 */ RC_INT | RC_R0,
    /* r1 */ RC_INT | RC_R1,
    /* r2 */ RC_INT | RC_R2,
    /* r3 */ RC_INT | RC_R3,
    /* r12 */ RC_INT | RC_R12,
    /* f0 */ RC_FLOAT | RC_F0,
    /* f1 */ RC_FLOAT | RC_F1,
    /* f2 */ RC_FLOAT | RC_F2,
    /* f3 */ RC_FLOAT | RC_F3,
#ifdef TCC_ARM_VFP
 /* d4/s8 */ RC_FLOAT | RC_F4,
/* d5/s10 */ RC_FLOAT | RC_F5,
/* d6/s12 */ RC_FLOAT | RC_F6,
/* d7/s14 */ RC_FLOAT | RC_F7,
#endif
};

static int two2mask(int a,int b) {
  return (reg_classes[a]|reg_classes[b])&~(RC_INT|RC_FLOAT);
}

static int regmask(int r) {
  return reg_classes[r]&~(RC_INT|RC_FLOAT);
}

#ifdef TCC_ARM_VFP
#define T2CPR(t) (((t) & VT_BTYPE) != VT_FLOAT ? 0x100 : 0)
#endif

/* return registers for function */
#define REG_IRET TREG_R0 /* single word int return register */
#define REG_LRET TREG_R1 /* second word return register (for long long) */
#define REG_FRET TREG_F0 /* float return register */

#ifdef TCC_ARM_EABI
#define TOK___divdi3 TOK___aeabi_ldivmod
#define TOK___moddi3 TOK___aeabi_ldivmod
#define TOK___udivdi3 TOK___aeabi_uldivmod
#define TOK___umoddi3 TOK___aeabi_uldivmod
#endif

/* defined if function parameters must be evaluated in reverse order */
#define INVERT_FUNC_PARAMS

/* defined if structures are passed as pointers. Otherwise structures
   are directly pushed on stack. */
//#define FUNC_STRUCT_PARAM_AS_PTR

#if defined(TCC_ARM_EABI) && defined(TCC_ARM_VFP)
static CType float_type, double_type, func_float_type, func_double_type;
#define func_ldouble_type func_double_type
#else
#define func_float_type func_old_type
#define func_double_type func_old_type
#define func_ldouble_type func_old_type
#endif

/* pointer size, in bytes */
#define PTR_SIZE 4

/* long double size and alignment, in bytes */
#ifdef TCC_ARM_VFP
#define LDOUBLE_SIZE  8
#endif

#ifndef LDOUBLE_SIZE
#define LDOUBLE_SIZE  8
#endif

#ifdef TCC_ARM_EABI
#define LDOUBLE_ALIGN 8
#else
#define LDOUBLE_ALIGN 4
#endif

/* maximum alignment (for aligned attribute support) */
#define MAX_ALIGN     8

#define CHAR_IS_UNSIGNED

/******************************************************/
/* ELF defines */

#define EM_TCC_TARGET EM_ARM

/* relocation type for 32 bit data relocation */
#define R_DATA_32   R_ARM_ABS32
#define R_JMP_SLOT  R_ARM_JUMP_SLOT
#define R_COPY      R_ARM_COPY

#define ELF_START_ADDR 0x00008000
#define ELF_PAGE_SIZE  0x1000

/******************************************************/
static unsigned long func_sub_sp_offset,last_itod_magic;
static int leaffunc;

void o(unsigned long i)
{
  /* this is a good place to start adding big-endian support*/
  int ind1;

  ind1 = ind + 4;
  if (!cur_text_section)
    error("compiler error! This happens f.ex. if the compiler\n"
         "can't evaluate constant expressions outside of a function.");
  if (ind1 > cur_text_section->data_allocated)
    section_realloc(cur_text_section, ind1);
  cur_text_section->data[ind++] = i&255;
  i>>=8;
  cur_text_section->data[ind++] = i&255;
  i>>=8; 
  cur_text_section->data[ind++] = i&255;
  i>>=8;
  cur_text_section->data[ind++] = i;
}

static unsigned long stuff_const(unsigned long op,unsigned long c)
{
  int try_neg=0;
  unsigned long nc = 0,negop = 0;

  switch(op&0x1F00000)
  {
    case 0x800000: //add
    case 0x400000: //sub
      try_neg=1;
      negop=op^0xC00000;
      nc=-c;
      break;
    case 0x1A00000: //mov
    case 0x1E00000: //mvn
      try_neg=1;
      negop=op^0x400000;
      nc=~c;
      break;
    case 0x200000: //xor
      if(c==~0)
	return (op&0xF010F000)|((op>>16)&0xF)|0x1E00000;
      break;
    case 0x0: //and
      if(c==~0)
	return (op&0xF010F000)|((op>>16)&0xF)|0x1A00000;
    case 0x1C00000: //bic
      try_neg=1;
      negop=op^0x1C00000;
      nc=~c;
      break;
    case 0x1800000: //orr
      if(c==~0)
	return (op&0xFFF0FFFF)|0x1E00000;
      break;
  }
  do {
    unsigned long m;
    int i;
    if(c<256) /* catch undefined <<32 */
      return op|c;
    for(i=2;i<32;i+=2) {
      m=(0xff>>i)|(0xff<<(32-i));
      if(!(c&~m))
	return op|(i<<7)|(c<<i)|(c>>(32-i));
    }
    op=negop;
    c=nc;
  } while(try_neg--);
  return 0;
}


//only add,sub
void stuff_const_harder(unsigned long op,unsigned long v) {
  unsigned long x;
  x=stuff_const(op,v);
  if(x)
    o(x);
  else {
    unsigned long a[16],nv,no,o2,n2;
    int i,j,k;
    a[0]=0xff;
    o2=(op&0xfff0ffff)|((op&0xf000)<<4);;
    for(i=1;i<16;i++)
      a[i]=(a[i-1]>>2)|(a[i-1]<<30);
    for(i=0;i<12;i++)
      for(j=i<4?i+12:15;j>=i+4;j--)
	if((v&(a[i]|a[j]))==v) {
	  o(stuff_const(op,v&a[i]));
	  o(stuff_const(o2,v&a[j]));
	  return;
	}
    no=op^0xC00000;
    n2=o2^0xC00000;
    nv=-v;
    for(i=0;i<12;i++)
      for(j=i<4?i+12:15;j>=i+4;j--)
	if((nv&(a[i]|a[j]))==nv) {
	  o(stuff_const(no,nv&a[i]));
	  o(stuff_const(n2,nv&a[j]));
	  return;
	}
    for(i=0;i<8;i++)
      for(j=i+4;j<12;j++)
	for(k=i<4?i+12:15;k>=j+4;k--)
	  if((v&(a[i]|a[j]|a[k]))==v) {
	    o(stuff_const(op,v&a[i]));
	    o(stuff_const(o2,v&a[j]));
	    o(stuff_const(o2,v&a[k]));
	    return;
	  }
    no=op^0xC00000;
    nv=-v;
    for(i=0;i<8;i++)
      for(j=i+4;j<12;j++)
	for(k=i<4?i+12:15;k>=j+4;k--)
	  if((nv&(a[i]|a[j]|a[k]))==nv) {
	    o(stuff_const(no,nv&a[i]));
	    o(stuff_const(n2,nv&a[j]));
	    o(stuff_const(n2,nv&a[k]));
	    return;
	  }
    o(stuff_const(op,v&a[0]));
    o(stuff_const(o2,v&a[4]));
    o(stuff_const(o2,v&a[8]));
    o(stuff_const(o2,v&a[12]));
  }
}

unsigned long encbranch(int pos,int addr,int fail)
{
  addr-=pos+8;
  addr/=4;
  if(addr>=0x1000000 || addr<-0x1000000) {
    if(fail)
      error("FIXME: function bigger than 32MB");
    return 0;
  }
  return 0x0A000000|(addr&0xffffff);
}

int decbranch(int pos)
{
  int x;
  x=*(int *)(cur_text_section->data + pos);
  x&=0x00ffffff;
  if(x&0x800000)
    x-=0x1000000;
  return x*4+pos+8;
}

/* output a symbol and patch all calls to it */
void gsym_addr(int t, int a)
{
  unsigned long *x;
  int lt;
  while(t) {
    x=(unsigned long *)(cur_text_section->data + t);
    t=decbranch(lt=t);
    if(a==lt+4)
      *x=0xE1A00000; // nop
    else {
      *x &= 0xff000000;
      *x |= encbranch(lt,a,1);
    }
  }
}

void gsym(int t)
{
  gsym_addr(t, ind);
}

#ifdef TCC_ARM_VFP
static unsigned long vfpr(int r)
{
  if(r<TREG_F0 || r>TREG_F7)
    error("compiler error! register %i is no vfp register",r);
  return r-5;
}
#else
static unsigned long fpr(int r)
{
  if(r<TREG_F0 || r>TREG_F3)
    error("compiler error! register %i is no fpa register",r);
  return r-5;
}
#endif

static unsigned long intr(int r)
{
  if(r==4)
    return 12;
  if((r<0 || r>4) && r!=14)
    error("compiler error! register %i is no int register",r);
  return r;
}

static void calcaddr(unsigned long *base,int *off,int *sgn,int maxoff,unsigned shift)
{
  if(*off>maxoff || *off&((1<<shift)-1)) {
    unsigned long x,y;
    x=0xE280E000;
    if(*sgn)
      x=0xE240E000;
    x|=(*base)<<16;
    *base=14; // lr
    y=stuff_const(x,*off&~maxoff);
    if(y) {
      o(y);
      *off&=maxoff;
      return;
    }
    y=stuff_const(x,(*off+maxoff)&~maxoff);
    if(y) {
      o(y);
      *sgn=!*sgn;
      *off=((*off+maxoff)&~maxoff)-*off;
      return;
    }
    stuff_const_harder(x,*off&~maxoff);
    *off&=maxoff;
  }
}

static unsigned long mapcc(int cc)
{
  switch(cc)
  {
    case TOK_ULT:
      return 0x30000000; /* CC/LO */
    case TOK_UGE:
      return 0x20000000; /* CS/HS */
    case TOK_EQ:
      return 0x00000000; /* EQ */
    case TOK_NE:
      return 0x10000000; /* NE */
    case TOK_ULE:
      return 0x90000000; /* LS */
    case TOK_UGT:
      return 0x80000000; /* HI */
    case TOK_Nset:
      return 0x40000000; /* MI */
    case TOK_Nclear:
      return 0x50000000; /* PL */
    case TOK_LT:
      return 0xB0000000; /* LT */
    case TOK_GE:
      return 0xA0000000; /* GE */
    case TOK_LE:
      return 0xD0000000; /* LE */
    case TOK_GT:
      return 0xC0000000; /* GT */
  }
  error("unexpected condition code");
  return 0xE0000000; /* AL */
}

static int negcc(int cc)
{
  switch(cc)
  {
    case TOK_ULT:
      return TOK_UGE;
    case TOK_UGE:
      return TOK_ULT;
    case TOK_EQ:
      return TOK_NE;
    case TOK_NE:
      return TOK_EQ;
    case TOK_ULE:
      return TOK_UGT;
    case TOK_UGT:
      return TOK_ULE;
    case TOK_Nset:
      return TOK_Nclear;
    case TOK_Nclear:
      return TOK_Nset;
    case TOK_LT:
      return TOK_GE;
    case TOK_GE:
      return TOK_LT;
    case TOK_LE:
      return TOK_GT;
    case TOK_GT:
      return TOK_LE;
  }
  error("unexpected condition code");
  return TOK_NE;
}

/* load 'r' from value 'sv' */
void load(int r, SValue *sv)
{
  int v, ft, fc, fr, sign;
  unsigned long op;
  SValue v1;

  fr = sv->r;
  ft = sv->type.t;
  fc = sv->c.ul;

  if(fc>=0)
    sign=0;
  else {
    sign=1;
    fc=-fc;
  }
  
  v = fr & VT_VALMASK;
  if (fr & VT_LVAL) {
    unsigned long base=0xB; // fp
    if(v == VT_LLOCAL) {
      v1.type.t = VT_PTR;
      v1.r = VT_LOCAL | VT_LVAL;
      v1.c.ul = sv->c.ul;
      load(base=14 /* lr */, &v1);
      fc=sign=0;
      v=VT_LOCAL;
    } else if(v == VT_CONST) {
      v1.type.t = VT_PTR;
      v1.r = fr&~VT_LVAL;
      v1.c.ul = sv->c.ul;
      v1.sym=sv->sym;
      load(base=14, &v1);
      fc=sign=0;
      v=VT_LOCAL;
    } else if(v < VT_CONST) {
      base=intr(v);
      fc=sign=0;
      v=VT_LOCAL;
    }
    if(v == VT_LOCAL) {
      if(is_float(ft)) {
	calcaddr(&base,&fc,&sign,1020,2);
#ifdef TCC_ARM_VFP
        op=0xED100A00; /* flds */
        if(!sign)
          op|=0x800000;
        if ((ft & VT_BTYPE) != VT_FLOAT)
          op|=0x100;   /* flds -> fldd */
        o(op|(vfpr(r)<<12)|(fc>>2)|(base<<16));
#else
	op=0xED100100;
	if(!sign)
	  op|=0x800000;
#if LDOUBLE_SIZE == 8
	if ((ft & VT_BTYPE) != VT_FLOAT)
	  op|=0x8000;
#else
	if ((ft & VT_BTYPE) == VT_DOUBLE)
	  op|=0x8000;
	else if ((ft & VT_BTYPE) == VT_LDOUBLE)
	  op|=0x400000;
#endif
	o(op|(fpr(r)<<12)|(fc>>2)|(base<<16));
#endif
      } else if((ft & (VT_BTYPE|VT_UNSIGNED)) == VT_BYTE
                || (ft & VT_BTYPE) == VT_SHORT) {
	calcaddr(&base,&fc,&sign,255,0);
	op=0xE1500090;
	if ((ft & VT_BTYPE) == VT_SHORT)
	  op|=0x20;
	if ((ft & VT_UNSIGNED) == 0)
	  op|=0x40;
	if(!sign)
	  op|=0x800000;
	o(op|(intr(r)<<12)|(base<<16)|((fc&0xf0)<<4)|(fc&0xf));
      } else {
	calcaddr(&base,&fc,&sign,4095,0);
	op=0xE5100000;
	if(!sign)
	  op|=0x800000;
        if ((ft & VT_BTYPE) == VT_BYTE)
          op|=0x400000;
        o(op|(intr(r)<<12)|fc|(base<<16));
      }
      return;
    }
  } else {
    if (v == VT_CONST) {
      op=stuff_const(0xE3A00000|(intr(r)<<12),sv->c.ul);
      if (fr & VT_SYM || !op) {
        o(0xE59F0000|(intr(r)<<12));
        o(0xEA000000);
        if(fr & VT_SYM)
	  greloc(cur_text_section, sv->sym, ind, R_ARM_ABS32);
        o(sv->c.ul);
      } else
        o(op);
      return;
    } else if (v == VT_LOCAL) {
      op=stuff_const(0xE28B0000|(intr(r)<<12),sv->c.ul);
      if (fr & VT_SYM || !op) {
	o(0xE59F0000|(intr(r)<<12));
	o(0xEA000000);
	if(fr & VT_SYM) // needed ?
	  greloc(cur_text_section, sv->sym, ind, R_ARM_ABS32);
	o(sv->c.ul);
	o(0xE08B0000|(intr(r)<<12)|intr(r));
      } else
	o(op);
      return;
    } else if(v == VT_CMP) {
      o(mapcc(sv->c.ul)|0x3A00001|(intr(r)<<12));
      o(mapcc(negcc(sv->c.ul))|0x3A00000|(intr(r)<<12));
      return;
    } else if (v == VT_JMP || v == VT_JMPI) {
      int t;
      t = v & 1;
      o(0xE3A00000|(intr(r)<<12)|t);
      o(0xEA000000);
      gsym(sv->c.ul);
      o(0xE3A00000|(intr(r)<<12)|(t^1));
      return;
    } else if (v < VT_CONST) {
      if(is_float(ft))
#ifdef TCC_ARM_VFP
        o(0xEEB00A40|(vfpr(r)<<12)|vfpr(v)|T2CPR(ft)); /* fcpyX */
#else
	o(0xEE008180|(fpr(r)<<12)|fpr(v));
#endif
      else
	o(0xE1A00000|(intr(r)<<12)|intr(v));
      return;
    }
  }
  error("load unimplemented!");
}

/* store register 'r' in lvalue 'v' */
void store(int r, SValue *sv)
{
  SValue v1;
  int v, ft, fc, fr, sign;
  unsigned long op;

  fr = sv->r;
  ft = sv->type.t;
  fc = sv->c.ul;

  if(fc>=0)
    sign=0;
  else {
    sign=1;
    fc=-fc;
  }
  
  v = fr & VT_VALMASK; 
  if (fr & VT_LVAL || fr == VT_LOCAL) {
    unsigned long base=0xb;
    if(v < VT_CONST) {
      base=intr(v);
      v=VT_LOCAL;
      fc=sign=0;
    } else if(v == VT_CONST) {
      v1.type.t = ft;
      v1.r = fr&~VT_LVAL;
      v1.c.ul = sv->c.ul;
      v1.sym=sv->sym;
      load(base=14, &v1);
      fc=sign=0;
      v=VT_LOCAL;   
    }
    if(v == VT_LOCAL) {
       if(is_float(ft)) {
	calcaddr(&base,&fc,&sign,1020,2);
#ifdef TCC_ARM_VFP
        op=0xED000A00; /* fsts */
        if(!sign) 
          op|=0x800000; 
        if ((ft & VT_BTYPE) != VT_FLOAT) 
          op|=0x100;   /* fsts -> fstd */
        o(op|(vfpr(r)<<12)|(fc>>2)|(base<<16));
#else
	op=0xED000100;
	if(!sign)
	  op|=0x800000;
#if LDOUBLE_SIZE == 8
	if ((ft & VT_BTYPE) != VT_FLOAT)
	  op|=0x8000;
#else
	if ((ft & VT_BTYPE) == VT_DOUBLE)
	  op|=0x8000;
	if ((ft & VT_BTYPE) == VT_LDOUBLE)
	  op|=0x400000;
#endif
	o(op|(fpr(r)<<12)|(fc>>2)|(base<<16));
#endif
	return;
      } else if((ft & VT_BTYPE) == VT_SHORT) {
	calcaddr(&base,&fc,&sign,255,0);
	op=0xE14000B0;
	if(!sign)
	  op|=0x800000;
	o(op|(intr(r)<<12)|(base<<16)|((fc&0xf0)<<4)|(fc&0xf));
      } else {
	calcaddr(&base,&fc,&sign,4095,0);
	op=0xE5000000;
	if(!sign)
	  op|=0x800000;
        if ((ft & VT_BTYPE) == VT_BYTE)
          op|=0x400000;
        o(op|(intr(r)<<12)|fc|(base<<16));
      }
      return;
    }
  }
  error("store unimplemented");
}

static void gadd_sp(int val)
{
  stuff_const_harder(0xE28DD000,val);
}

/* 'is_jmp' is '1' if it is a jump */
static void gcall_or_jmp(int is_jmp)
{
  int r;
  if ((vtop->r & (VT_VALMASK | VT_LVAL)) == VT_CONST) {
    unsigned long x;
    /* constant case */
    x=encbranch(ind,ind+vtop->c.ul,0);
    if(x) {
      if (vtop->r & VT_SYM) {
	/* relocation case */
	greloc(cur_text_section, vtop->sym, ind, R_ARM_PC24);
      } else
	put_elf_reloc(symtab_section, cur_text_section, ind, R_ARM_PC24, 0);
      o(x|(is_jmp?0xE0000000:0xE1000000));
    } else {
      if(!is_jmp)
	o(0xE28FE004); // add lr,pc,#4
      o(0xE51FF004);   // ldr pc,[pc,#-4]
      if (vtop->r & VT_SYM)
	greloc(cur_text_section, vtop->sym, ind, R_ARM_ABS32);
      o(vtop->c.ul);
    }
  } else {
    /* otherwise, indirect call */
    r = gv(RC_INT);
    if(!is_jmp)
      o(0xE1A0E00F);       // mov lr,pc
    o(0xE1A0F000|intr(r)); // mov pc,r
  }
}

/* Generate function call. The function address is pushed first, then
   all the parameters in call order. This functions pops all the
   parameters and the function address. */
void gfunc_call(int nb_args)
{
  int size, align, r, args_size, i;
  Sym *func_sym;
  signed char plan[4][2]={{-1,-1},{-1,-1},{-1,-1},{-1,-1}};
  int todo=0xf, keep, plan2[4]={0,0,0,0};

  r = vtop->r & VT_VALMASK;
  if (r == VT_CMP || (r & ~1) == VT_JMP)
    gv(RC_INT);
#ifdef TCC_ARM_EABI
  if((vtop[-nb_args].type.ref->type.t & VT_BTYPE) == VT_STRUCT
     && type_size(&vtop[-nb_args].type, &align) <= 4) {
    SValue tmp;
    tmp=vtop[-nb_args];
    vtop[-nb_args]=vtop[-nb_args+1];
    vtop[-nb_args+1]=tmp;
    --nb_args;
  }
  
  vpushi(0);
  vtop->type.t = VT_LLONG;
  args_size = 0;
  for(i = nb_args + 1 ; i-- ;) {
    size = type_size(&vtop[-i].type, &align);
    if(args_size & (align-1)) {
      vpushi(0);
      vtop->type.t = VT_VOID; /* padding */
      vrott(i+2);
      args_size += 4;
      ++nb_args;
    }
    args_size += (size + 3) & -4;
  }
  vtop--;
#endif
  args_size = 0;
  for(i = nb_args ; i-- && args_size < 16 ;) {
    switch(vtop[-i].type.t & VT_BTYPE) {
      case VT_STRUCT:
      case VT_FLOAT:
      case VT_DOUBLE:
      case VT_LDOUBLE:
      size = type_size(&vtop[-i].type, &align);
        size = (size + 3) & -4;
      args_size += size;
        break;
      default:
      plan[nb_args-1-i][0]=args_size/4;
      args_size += 4;
      if ((vtop[-i].type.t & VT_BTYPE) == VT_LLONG && args_size < 16) {
	plan[nb_args-1-i][1]=args_size/4;
	args_size += 4;
      }
    }
  }
  args_size = keep = 0;
  for(i = 0;i < nb_args; i++) {
    vnrott(keep+1);
    if ((vtop->type.t & VT_BTYPE) == VT_STRUCT) {
      size = type_size(&vtop->type, &align);
      /* align to stack align size */
      size = (size + 3) & -4;
      /* allocate the necessary size on stack */
      gadd_sp(-size);
      /* generate structure store */
      r = get_reg(RC_INT);
      o(0xE1A0000D|(intr(r)<<12));
      vset(&vtop->type, r | VT_LVAL, 0);
      vswap();
      vstore();
      vtop--;
      args_size += size;
    } else if (is_float(vtop->type.t)) {
#ifdef TCC_ARM_VFP
      r=vfpr(gv(RC_FLOAT))<<12;
      size=4;
      if ((vtop->type.t & VT_BTYPE) != VT_FLOAT)
      {
        size=8;
        r|=0x101; /* fstms -> fstmd */
      }
      o(0xED2D0A01+r);
#else
      r=fpr(gv(RC_FLOAT))<<12;
      if ((vtop->type.t & VT_BTYPE) == VT_FLOAT)
        size = 4;
      else if ((vtop->type.t & VT_BTYPE) == VT_DOUBLE)
        size = 8;
      else
        size = LDOUBLE_SIZE;
      
      if (size == 12)
	r|=0x400000;
      else if(size == 8)
	r|=0x8000;

      o(0xED2D0100|r|(size>>2));
#endif
      vtop--;
      args_size += size;
    } else {
      int s;
      /* simple type (currently always same size) */
      /* XXX: implicit cast ? */
      size=4;
      if ((vtop->type.t & VT_BTYPE) == VT_LLONG) {
	lexpand_nr();
	s=RC_INT;
	if(nb_args-i<5 && plan[nb_args-i-1][1]!=-1) {
	  s=regmask(plan[nb_args-i-1][1]);
	  todo&=~(1<<plan[nb_args-i-1][1]);
	}
	if(s==RC_INT) {
	  r = gv(s);
	  o(0xE52D0004|(intr(r)<<12)); /* str r,[sp,#-4]! */
	  vtop--;
	} else {
	  plan2[keep]=s;
	  keep++;
          vswap();
	}
	size = 8;
      }
      s=RC_INT;
      if(nb_args-i<5 && plan[nb_args-i-1][0]!=-1) {
        s=regmask(plan[nb_args-i-1][0]);
	todo&=~(1<<plan[nb_args-i-1][0]);
      }
#ifdef TCC_ARM_EABI
      if(vtop->type.t == VT_VOID) {
        if(s == RC_INT)
          o(0xE24DD004); /* sub sp,sp,#4 */
        vtop--;
      } else
#endif      
      if(s == RC_INT) {
	r = gv(s);
	o(0xE52D0004|(intr(r)<<12)); /* str r,[sp,#-4]! */
	vtop--;
      } else {
	plan2[keep]=s;
	keep++;
      }
      args_size += size;
    }
  }
  for(i=keep;i--;) {
    gv(plan2[i]);
    vrott(keep);
  }
save_regs(keep); /* save used temporary registers */
  keep++;
  if(args_size) {
    int n;
    n=args_size/4;
    if(n>4)
      n=4;
    todo&=((1<<n)-1);
    if(todo) {
      int i;
      o(0xE8BD0000|todo);
      for(i=0;i<4;i++)
	if(todo&(1<<i)) {
	  vpushi(0);
	  vtop->r=i;
	  keep++;
	}
    }
    args_size-=n*4;
  }
  vnrott(keep);
  func_sym = vtop->type.ref;
  gcall_or_jmp(0);
  if (args_size)
      gadd_sp(args_size);
#ifdef TCC_ARM_EABI
  if((vtop->type.ref->type.t & VT_BTYPE) == VT_STRUCT
     && type_size(&vtop->type.ref->type, &align) <= 4)
  {
    store(REG_IRET,vtop-keep);
    ++keep;
  }
#ifdef TCC_ARM_VFP
  else if(is_float(vtop->type.ref->type.t)) {
    if((vtop->type.ref->type.t & VT_BTYPE) == VT_FLOAT) {
      o(0xEE000A10); /* fmsr s0,r0 */
    } else {
      o(0xEE000B10); /* fmdlr d0,r0 */
      o(0xEE201B10); /* fmdhr d0,r1 */
    }
  }
#endif
#endif
  vtop-=keep;
  leaffunc = 0;
}

/* generate function prolog of type 't' */
void gfunc_prolog(CType *func_type)
{
  Sym *sym,*sym2;
  int n,addr,size,align;

  sym = func_type->ref;
  func_vt = sym->type;
  
  n = 0;
  addr = 0;
  if((func_vt.t & VT_BTYPE) == VT_STRUCT
     && type_size(&func_vt,&align) > 4)
  {
    func_vc = addr;
    addr += 4;
    n++;
  }
  for(sym2=sym->next;sym2 && n<4;sym2=sym2->next) {
    size = type_size(&sym2->type, &align);
    n += (size + 3) / 4;
  }
  o(0xE1A0C00D); /* mov ip,sp */
  if(func_type->ref->c == FUNC_ELLIPSIS)
    n=4;
  if(n) {
    if(n>4)
      n=4;
#ifdef TCC_ARM_EABI
    n=(n+1)&-2;
#endif
    o(0xE92D0000|((1<<n)-1)); /* save r0-r4 on stack if needed */
  }
  o(0xE92D5800); /* save fp, ip, lr */
  o(0xE28DB00C); /* add fp, sp, #12 */
  func_sub_sp_offset = ind;
  o(0xE1A00000); /* nop, leave space for stack adjustment */
  while ((sym = sym->next)) {
    CType *type;
    type = &sym->type;
    size = type_size(type, &align);
    size = (size + 3) & -4;
#ifdef TCC_ARM_EABI
    addr = (addr + align - 1) & -align;
#endif
    sym_push(sym->v & ~SYM_FIELD, type, VT_LOCAL | lvalue_type(type->t), addr);
    addr += size;
  }
  last_itod_magic=0;
  leaffunc = 1;
  loc = -12;
}

/* generate function epilog */
void gfunc_epilog(void)
{
  unsigned long x;
  int diff;
#ifdef TCC_ARM_EABI
  if(is_float(func_vt.t)) {
    if((func_vt.t & VT_BTYPE) == VT_FLOAT)
      o(0xEE100A10); /* fmrs r0, s0 */
    else {
      o(0xEE100B10); /* fmrdl r0, d0 */
      o(0xEE301B10); /* fmrdh r1, d0 */
    }
  }
#endif
  o(0xE91BA800); /* restore fp, sp, pc */
  diff = (-loc + 3) & -4;
#ifdef TCC_ARM_EABI
  if(!leaffunc)
    diff = (diff + 7) & -8;
#endif
  if(diff > 12) {
    x=stuff_const(0xE24BD000, diff); /* sub sp,fp,# */
    if(x)
      *(unsigned long *)(cur_text_section->data + func_sub_sp_offset) = x;
    else {
      unsigned long addr;
      addr=ind;
      o(0xE59FC004); /* ldr ip,[pc+4] */
      o(0xE04BD00C); /* sub sp,fp,ip  */
      o(0xE1A0F00E); /* mov pc,lr */
      o(diff);
      *(unsigned long *)(cur_text_section->data + func_sub_sp_offset) = 0xE1000000|encbranch(func_sub_sp_offset,addr,1);
    }
  }
}

/* generate a jump to a label */
int gjmp(int t)
{
  int r;
  r=ind;
  o(0xE0000000|encbranch(r,t,1));
  return r;
}

/* generate a jump to a fixed address */
void gjmp_addr(int a)
{
  gjmp(a);
}

/* generate a test. set 'inv' to invert test. Stack entry is popped */
int gtst(int inv, int t)
{
  int v, r;
  unsigned long op;
  v = vtop->r & VT_VALMASK;
  r=ind;
  if (v == VT_CMP) {
    op=mapcc(inv?negcc(vtop->c.i):vtop->c.i);
    op|=encbranch(r,t,1);
    o(op);
    t=r;
  } else if (v == VT_JMP || v == VT_JMPI) {
    if ((v & 1) == inv) {
      if(!vtop->c.i)
	vtop->c.i=t;
      else {
	unsigned long *x;
	int p,lp;
	if(t) {
          p = vtop->c.i;
          do {
	    p = decbranch(lp=p);
          } while(p);
	  x = (unsigned long *)(cur_text_section->data + lp);
	  *x &= 0xff000000;
	  *x |= encbranch(lp,t,1);
	}
	t = vtop->c.i;
      }
    } else {
      t = gjmp(t);
      gsym(vtop->c.i);
    }
  } else {
    if (is_float(vtop->type.t)) {
      r=gv(RC_FLOAT);
#ifdef TCC_ARM_VFP
      o(0xEEB50A40|(vfpr(r)<<12)|T2CPR(vtop->type.t)); /* fcmpzX */
      o(0xEEF1FA10); /* fmstat */
#else
      o(0xEE90F118|(fpr(r)<<16));
#endif
      vtop->r = VT_CMP;
      vtop->c.i = TOK_NE;
      return gtst(inv, t);
    } else if ((vtop->r & (VT_VALMASK | VT_LVAL | VT_SYM)) == VT_CONST) {
      /* constant jmp optimization */
      if ((vtop->c.i != 0) != inv) 
	t = gjmp(t);
    } else {
      v = gv(RC_INT);
      o(0xE3300000|(intr(v)<<16));
      vtop->r = VT_CMP;
      vtop->c.i = TOK_NE;
      return gtst(inv, t);
    }   
  }
  vtop--;
  return t;
}

/* generate an integer binary operation */
void gen_opi(int op)
{
  int c, func = 0;
  unsigned long opc = 0,r,fr;
  unsigned short retreg = REG_IRET;

  c=0;
  switch(op) {
    case '+':
      opc = 0x8;
      c=1;
      break;
    case TOK_ADDC1: /* add with carry generation */
      opc = 0x9;
      c=1;
      break;
    case '-':
      opc = 0x4;
      c=1;
      break;
    case TOK_SUBC1: /* sub with carry generation */
      opc = 0x5;
      c=1;
      break;
    case TOK_ADDC2: /* add with carry use */
      opc = 0xA;
      c=1;
      break;
    case TOK_SUBC2: /* sub with carry use */
      opc = 0xC;
      c=1;
      break;
    case '&':
      opc = 0x0;
      c=1;
      break;
    case '^':
      opc = 0x2;
      c=1;
      break;
    case '|':
      opc = 0x18;
      c=1;
      break;
    case '*':
      gv2(RC_INT, RC_INT);
      r = vtop[-1].r;
      fr = vtop[0].r;
      vtop--;
      o(0xE0000090|(intr(r)<<16)|(intr(r)<<8)|intr(fr));
      return;
    case TOK_SHL:
      opc = 0;
      c=2;
      break;
    case TOK_SHR:
      opc = 1;
      c=2;
      break;
    case TOK_SAR:
      opc = 2;
      c=2;
      break;
    case '/':
    case TOK_PDIV:
      func=TOK___divsi3;
      c=3;
      break;
    case TOK_UDIV:
      func=TOK___udivsi3;
      c=3;
      break;
    case '%':
#ifdef TCC_ARM_EABI
      func=TOK___aeabi_idivmod;
      retreg=REG_LRET;
#else
      func=TOK___modsi3;
#endif
      c=3;
      break;
    case TOK_UMOD:
#ifdef TCC_ARM_EABI
      func=TOK___aeabi_uidivmod;
      retreg=REG_LRET;
#else
      func=TOK___umodsi3;
#endif
      c=3;
      break;
    case TOK_UMULL:
      gv2(RC_INT, RC_INT);
      r=intr(vtop[-1].r2=get_reg(RC_INT));
      c=vtop[-1].r;
      vtop[-1].r=get_reg_ex(RC_INT,regmask(c));
      vtop--;
      o(0xE0800090|(r<<16)|(intr(vtop->r)<<12)|(intr(c)<<8)|intr(vtop[1].r));
      return;
    default:
      opc = 0x15;
      c=1;
      break;
  }
  switch(c) {
    case 1:
      if((vtop[-1].r & (VT_VALMASK | VT_LVAL | VT_SYM)) == VT_CONST) {
	if(opc == 4 || opc == 5 || opc == 0xc) {
	  vswap();
	  opc|=2; // sub -> rsb
	}
      }
      if ((vtop->r & VT_VALMASK) == VT_CMP ||
          (vtop->r & (VT_VALMASK & ~1)) == VT_JMP)
        gv(RC_INT);
      vswap();
      c=intr(gv(RC_INT));
      vswap();
      opc=0xE0000000|(opc<<20)|(c<<16);
      if((vtop->r & (VT_VALMASK | VT_LVAL | VT_SYM)) == VT_CONST) {
	unsigned long x;
	x=stuff_const(opc|0x2000000,vtop->c.i);
	if(x) {
	  r=intr(vtop[-1].r=get_reg_ex(RC_INT,regmask(vtop[-1].r)));
	  o(x|(r<<12));
	  goto done;
	}
      }
      fr=intr(gv(RC_INT));
      r=intr(vtop[-1].r=get_reg_ex(RC_INT,two2mask(vtop->r,vtop[-1].r)));
      o(opc|(r<<12)|fr);
done:
      vtop--;
      if (op >= TOK_ULT && op <= TOK_GT) {
        vtop->r = VT_CMP;
        vtop->c.i = op;
      }
      break;
    case 2:
      opc=0xE1A00000|(opc<<5);
      if ((vtop->r & VT_VALMASK) == VT_CMP ||
          (vtop->r & (VT_VALMASK & ~1)) == VT_JMP)
        gv(RC_INT);
      vswap();
      r=intr(gv(RC_INT));
      vswap();
      opc|=r;
      if ((vtop->r & (VT_VALMASK | VT_LVAL | VT_SYM)) == VT_CONST) {
	fr=intr(vtop[-1].r=get_reg_ex(RC_INT,regmask(vtop[-1].r)));
	c = vtop->c.i & 0x1f;
	o(opc|(c<<7)|(fr<<12));
      } else {
        fr=intr(gv(RC_INT));
	c=intr(vtop[-1].r=get_reg_ex(RC_INT,two2mask(vtop->r,vtop[-1].r)));
	o(opc|(c<<12)|(fr<<8)|0x10);
      }
      vtop--;
      break;
    case 3:
      vpush_global_sym(&func_old_type, func);
      vrott(3);
      gfunc_call(2);
      vpushi(0);
      vtop->r = retreg;
      break;
    default:
      error("gen_opi %i unimplemented!",op);
  }
}

#ifdef TCC_ARM_VFP
static int is_zero(int i)
{
  if((vtop[i].r & (VT_VALMASK | VT_LVAL | VT_SYM)) != VT_CONST)
    return 0;
  if (vtop[i].type.t == VT_FLOAT)
    return (vtop[i].c.f == 0.f);
  else if (vtop[i].type.t == VT_DOUBLE)
    return (vtop[i].c.d == 0.0);
  return (vtop[i].c.ld == 0.l);
}

/* generate a floating point operation 'v = t1 op t2' instruction. The
 *    two operands are guaranted to have the same floating point type */
void gen_opf(int op)
{
  unsigned long x;
  int fneg=0,r;
  x=0xEE000A00|T2CPR(vtop->type.t);
  switch(op) {
    case '+':
      if(is_zero(-1))
        vswap();
      if(is_zero(0)) {
        vtop--;
        return;
      }
      x|=0x300000;
      break;
    case '-':
      x|=0x300040;
      if(is_zero(0)) {
        vtop--;
        return;
      }
      if(is_zero(-1)) {
        x|=0x810000; /* fsubX -> fnegX */
        vswap();
        vtop--;
        fneg=1;
      }
      break;
    case '*':
      x|=0x200000;
      break;
    case '/':
      x|=0x800000;
      break;
    default:
      if(op < TOK_ULT && op > TOK_GT) {
        error("unknown fp op %x!",op);
        return;
      }
      if(is_zero(-1)) {
        vswap();
        switch(op) {
          case TOK_LT: op=TOK_GT; break;
          case TOK_GE: op=TOK_ULE; break;
          case TOK_LE: op=TOK_GE; break;
          case TOK_GT: op=TOK_ULT; break;
        }
      }
      x|=0xB40040; /* fcmpX */
      if(op!=TOK_EQ && op!=TOK_NE)
        x|=0x80; /* fcmpX -> fcmpeX */
      if(is_zero(0)) {
        vtop--;
        o(x|0x10000|(vfpr(gv(RC_FLOAT))<<12)); /* fcmp(e)X -> fcmp(e)zX */
      } else {
        x|=vfpr(gv(RC_FLOAT));
        vswap();
        o(x|(vfpr(gv(RC_FLOAT))<<12));
        vtop--;
      }
      o(0xEEF1FA10); /* fmstat */

      switch(op) {
        case TOK_LE: op=TOK_ULE; break;
        case TOK_LT: op=TOK_ULT; break;
        case TOK_UGE: op=TOK_GE; break;
        case TOK_UGT: op=TOK_GT; break;
      }
      
      vtop->r = VT_CMP;
      vtop->c.i = op;
      return;
  }
  r=gv(RC_FLOAT);
  x|=vfpr(r);
  r=regmask(r);
  if(!fneg) {
    int r2;
    vswap();
    r2=gv(RC_FLOAT);
    x|=vfpr(r2)<<16;
    r|=regmask(r2);
  }
  vtop->r=get_reg_ex(RC_FLOAT,r);
  if(!fneg)
    vtop--;
  o(x|(vfpr(vtop->r)<<12));
}

#else
static int is_fconst()
{
  long double f;
  int r;
  if((vtop->r & (VT_VALMASK | VT_LVAL | VT_SYM)) != VT_CONST)
    return 0;
  if (vtop->type.t == VT_FLOAT)
    f = vtop->c.f;
  else if (vtop->type.t == VT_DOUBLE)
    f = vtop->c.d;
  else
    f = vtop->c.ld;
  if(!ieee_finite(f))
    return 0;
  r=0x8;
  if(f<0.0) {
    r=0x18;
    f=-f;
  }
  if(f==0.0)
    return r;
  if(f==1.0)
    return r|1;
  if(f==2.0)
    return r|2;
  if(f==3.0)
    return r|3;
  if(f==4.0)
    return r|4;
  if(f==5.0)
    return r|5;
  if(f==0.5)
    return r|6;
  if(f==10.0)
    return r|7;
  return 0;
}

/* generate a floating point operation 'v = t1 op t2' instruction. The
   two operands are guaranted to have the same floating point type */
void gen_opf(int op)
{
  unsigned long x;
  int r,r2,c1,c2;
  //fputs("gen_opf\n",stderr);
  vswap();
  c1 = is_fconst();
  vswap();
  c2 = is_fconst();
  x=0xEE000100;
#if LDOUBLE_SIZE == 8
  if ((vtop->type.t & VT_BTYPE) != VT_FLOAT)
    x|=0x80;
#else
  if ((vtop->type.t & VT_BTYPE) == VT_DOUBLE)
    x|=0x80;
  else if ((vtop->type.t & VT_BTYPE) == VT_LDOUBLE)
    x|=0x80000;
#endif
  switch(op)
  {
    case '+':
      if(!c2) {
	vswap();
	c2=c1;
      }
      vswap();
      r=fpr(gv(RC_FLOAT));
      vswap();
      if(c2) {
	if(c2>0xf)
	  x|=0x200000; // suf
	r2=c2&0xf;
      } else {
	r2=fpr(gv(RC_FLOAT));
      }
      break;
    case '-':
      if(c2) {
	if(c2<=0xf)
	  x|=0x200000; // suf
	r2=c2&0xf;
	vswap();
	r=fpr(gv(RC_FLOAT));
	vswap();
      } else if(c1 && c1<=0xf) {
	x|=0x300000; // rsf
	r2=c1;
	r=fpr(gv(RC_FLOAT));
	vswap();
      } else {
	x|=0x200000; // suf
	vswap();
	r=fpr(gv(RC_FLOAT));
	vswap();
	r2=fpr(gv(RC_FLOAT));
      }
      break;
    case '*':
      if(!c2 || c2>0xf) {
	vswap();
	c2=c1;
      }
      vswap();
      r=fpr(gv(RC_FLOAT));
      vswap();
      if(c2 && c2<=0xf)
	r2=c2;
      else
	r2=fpr(gv(RC_FLOAT));
      x|=0x100000; // muf
      break;
    case '/':
      if(c2 && c2<=0xf) {
	x|=0x400000; // dvf
	r2=c2;
	vswap();
	r=fpr(gv(RC_FLOAT));
	vswap();
      } else if(c1 && c1<=0xf) {
	x|=0x500000; // rdf
	r2=c1;
	r=fpr(gv(RC_FLOAT));
	vswap();
      } else {
	x|=0x400000; // dvf
	vswap();
	r=fpr(gv(RC_FLOAT));
	vswap();
	r2=fpr(gv(RC_FLOAT));
      }     
      break;
    default:
      if(op >= TOK_ULT && op <= TOK_GT) {
	x|=0xd0f110; // cmfe
/* bug (intention?) in Linux FPU emulator
   doesn't set carry if equal */
	switch(op) {
	  case TOK_ULT:
	  case TOK_UGE:
	  case TOK_ULE:
	  case TOK_UGT:
            error("unsigned comparision on floats?");
	    break;
	  case TOK_LT:
            op=TOK_Nset;
	    break;
	  case TOK_LE:
            op=TOK_ULE; /* correct in unordered case only if AC bit in FPSR set */
	    break;
	  case TOK_EQ:
	  case TOK_NE:
	    x&=~0x400000; // cmfe -> cmf
	    break;
	}
	if(c1 && !c2) {
	  c2=c1;
	  vswap();
	  switch(op) {
            case TOK_Nset:
              op=TOK_GT;
	      break;
            case TOK_GE:
	      op=TOK_ULE;
	      break;
	    case TOK_ULE:
              op=TOK_GE;
	      break;
            case TOK_GT:
              op=TOK_Nset;
	      break;
	  }
	}
	vswap();
	r=fpr(gv(RC_FLOAT));
	vswap();
	if(c2) {
	  if(c2>0xf)
	    x|=0x200000;
	  r2=c2&0xf;
	} else {
	  r2=fpr(gv(RC_FLOAT));
	}
	vtop[-1].r = VT_CMP;
	vtop[-1].c.i = op;
      } else {
        error("unknown fp op %x!",op);
	return;
      }
  }
  if(vtop[-1].r == VT_CMP)
    c1=15;
  else {
    c1=vtop->r;
    if(r2&0x8)
      c1=vtop[-1].r;
    vtop[-1].r=get_reg_ex(RC_FLOAT,two2mask(vtop[-1].r,c1));
    c1=fpr(vtop[-1].r);
  }
  vtop--;
  o(x|(r<<16)|(c1<<12)|r2);
}
#endif

/* convert integers to fp 't' type. Must handle 'int', 'unsigned int'
   and 'long long' cases. */
void gen_cvt_itof1(int t)
{
  int r,r2,bt;
  bt=vtop->type.t & VT_BTYPE;
  if(bt == VT_INT || bt == VT_SHORT || bt == VT_BYTE) {
#ifndef TCC_ARM_VFP
    unsigned int dsize=0;
#endif
    r=intr(gv(RC_INT));
#ifdef TCC_ARM_VFP
    r2=vfpr(vtop->r=get_reg(RC_FLOAT));
    o(0xEE000A10|(r<<12)|(r2<<16)); /* fmsr */
    r2<<=12;
    if(!(vtop->type.t & VT_UNSIGNED))
      r2|=0x80;                /* fuitoX -> fsituX */
    o(0xEEB80A40|r2|T2CPR(t)); /* fYitoX*/
#else
    r2=fpr(vtop->r=get_reg(RC_FLOAT));
    if((t & VT_BTYPE) != VT_FLOAT)
      dsize=0x80;    /* flts -> fltd */
    o(0xEE000110|dsize|(r2<<16)|(r<<12)); /* flts */
    if((vtop->type.t & (VT_UNSIGNED|VT_BTYPE)) == (VT_UNSIGNED|VT_INT)) {
      unsigned int off=0;
      o(0xE3500000|(r<<12));        /* cmp */
      r=fpr(get_reg(RC_FLOAT));
      if(last_itod_magic) {
	off=ind+8-last_itod_magic;
	off/=4;
	if(off>255)
	  off=0;
      }
      o(0xBD1F0100|(r<<12)|off);    /* ldflts */
      if(!off) {
        o(0xEA000000);              /* b */
        last_itod_magic=ind;
        o(0x4F800000);              /* 4294967296.0f */
      }
      o(0xBE000100|dsize|(r2<<16)|(r2<<12)|r); /* adflt */
    }
#endif
    return;
  } else if(bt == VT_LLONG) {
    int func;
    CType *func_type = 0;
    if((t & VT_BTYPE) == VT_FLOAT) {
      func_type = &func_float_type;
      if(vtop->type.t & VT_UNSIGNED)
        func=TOK___floatundisf;
      else
        func=TOK___floatdisf;
#if LDOUBLE_SIZE != 8
    } else if((t & VT_BTYPE) == VT_LDOUBLE) {
      func_type = &func_ldouble_type;
      if(vtop->type.t & VT_UNSIGNED)
        func=TOK___floatundixf;
      else
        func=TOK___floatdixf;
    } else if((t & VT_BTYPE) == VT_DOUBLE) {
#else
    } else if((t & VT_BTYPE) == VT_DOUBLE || (t & VT_BTYPE) == VT_LDOUBLE) {
#endif
      func_type = &func_double_type;
      if(vtop->type.t & VT_UNSIGNED)
        func=TOK___floatundidf;
      else
        func=TOK___floatdidf;
    }
    if(func_type) {
      vpush_global_sym(func_type, func);
      vswap();
      gfunc_call(1);
      vpushi(0);
      vtop->r=TREG_F0;
      return;
    }
  }
  error("unimplemented gen_cvt_itof %x!",vtop->type.t);
}

/* convert fp to int 't' type */
void gen_cvt_ftoi(int t)
{
  int r,r2,u,func=0;
  u=t&VT_UNSIGNED;
  t&=VT_BTYPE;
  r2=vtop->type.t & VT_BTYPE;
  if(t==VT_INT) {
#ifdef TCC_ARM_VFP
    r=vfpr(gv(RC_FLOAT));
    u=u?0:0x10000;
    o(0xEEBC0A40|(r<<12)|r|T2CPR(r2)); /* ftoXiY */
    r2=intr(vtop->r=get_reg(RC_INT));
    o(0xEE100A10|(r<<16)|(r2<<12));
    return;
#else
    if(u) {
      if(r2 == VT_FLOAT)
        func=TOK___fixunssfsi;
#if LDOUBLE_SIZE != 8
      else if(r2 == VT_LDOUBLE)
	func=TOK___fixunsxfsi;
      else if(r2 == VT_DOUBLE)
#else
      else if(r2 == VT_LDOUBLE || r2 == VT_DOUBLE)
#endif
	func=TOK___fixunsdfsi;
    } else {
      r=fpr(gv(RC_FLOAT));
      r2=intr(vtop->r=get_reg(RC_INT));
      o(0xEE100170|(r2<<12)|r);
      return;
    }
#endif
  } else if(t == VT_LLONG) { // unsigned handled in gen_cvt_ftoi1
    if(r2 == VT_FLOAT)
      func=TOK___fixsfdi;
#if LDOUBLE_SIZE != 8
    else if(r2 == VT_LDOUBLE)
      func=TOK___fixxfdi;
    else if(r2 == VT_DOUBLE)
#else
    else if(r2 == VT_LDOUBLE || r2 == VT_DOUBLE)
#endif
      func=TOK___fixdfdi;
  }
  if(func) {
    vpush_global_sym(&func_old_type, func);
    vswap();
    gfunc_call(1);
    vpushi(0);
    if(t == VT_LLONG)
      vtop->r2 = REG_LRET;
    vtop->r = REG_IRET;
    return;
  }
  error("unimplemented gen_cvt_ftoi!");
}

/* convert from one floating point type to another */
void gen_cvt_ftof(int t)
{
#ifdef TCC_ARM_VFP
  if(((vtop->type.t & VT_BTYPE) == VT_FLOAT) != ((t & VT_BTYPE) == VT_FLOAT)) {
    int r=vfpr(gv(RC_FLOAT));
    o(0xEEB70AC0|(r<<12)|r|T2CPR(vtop->type.t));
  }
#else
  /* all we have to do on i386 and FPA ARM is to put the float in a register */
  gv(RC_FLOAT);
#endif
}

/* computed goto support */
void ggoto(void)
{
  gcall_or_jmp(1);
  vtop--;
}

/* end of ARM code generator */
/*************************************************************/

