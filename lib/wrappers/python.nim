#
#    Light-weight binding for the Python interpreter
#       (c) 2010 Andreas Rumpf
#    Based on 'PythonEngine' module by Dr. Dietmar Budelsky
#
#
#************************************************************************
#
# Module:  Unit 'PythonEngine'     Copyright (c) 1997
#
# Version: 3.0                     Dr. Dietmar Budelsky
# Sub-Version: 0.25                dbudelsky@web.de
#                                  Germany
#
#                                  Morgan Martinet
#                                  4721 rue Brebeuf
#                                  H2J 3L2 MONTREAL (QC)
#                                  CANADA
#                                  e-mail: mmm@free.fr
#
#  look our page at: http://www.multimania.com/marat
#************************************************************************
#  Functionality:  Delphi Components that provide an interface to the
#                  Python language (see python.txt for more infos on
#                  Python itself).
#
#************************************************************************
#  Contributors:
#      Grzegorz Makarewicz (mak@mikroplan.com.pl)
#      Andrew Robinson (andy@hps1.demon.co.uk)
#      Mark Watts(mark_watts@hotmail.com)
#      Olivier Deckmyn (olivier.deckmyn@mail.dotcom.fr)
#      Sigve Tjora (public@tjora.no)
#      Mark Derricutt (mark@talios.com)
#      Igor E. Poteryaev (jah@mail.ru)
#      Yuri Filimonov (fil65@mail.ru)
#      Stefan Hoffmeister (Stefan.Hoffmeister@Econos.de)
#************************************************************************
# This source code is distributed with no WARRANTY, for no reason or use.
# Everyone is allowed to use and change this code free for his own tasks
# and projects, as long as this header and its copyright text is intact.
# For changed versions of this code, which are public distributed the
# following additional conditions have to be fullfilled:
# 1) The header has to contain a comment on the change and the author of
#    it.
# 2) A copy of the changed source has to be sent to the above E-Mail
#    address or my then valid address, if this is possible to the
#    author.
# The second condition has the target to maintain an up to date central
# version of the component. If this condition is not acceptable for
# confidential or legal reasons, everyone is free to derive a component
# or to generate a diff file to my or other original sources.
# Dr. Dietmar Budelsky, 1997-11-17
#************************************************************************

{.deadCodeElim: on.}

import
  dynlib


when defined(windows):
  const dllname = "python(27|26|25|24|23|22|21|20|16|15).dll"
elif defined(macosx):
  const dllname = "libpython(2.7|2.6|2.5|2.4|2.3|2.2|2.1|2.0|1.6|1.5).dylib"
else:
  const dllver = ".1"
  const dllname = "libpython(2.7|2.6|2.5|2.4|2.3|2.2|2.1|2.0|1.6|1.5).so" &
                  dllver


const
  PYT_METHOD_BUFFER_INCREASE* = 10
  PYT_MEMBER_BUFFER_INCREASE* = 10
  PYT_GETSET_BUFFER_INCREASE* = 10
  METH_VARARGS* = 0x0001
  METH_KEYWORDS* = 0x0002 # Masks for the co_flags field of PyCodeObject
  CO_OPTIMIZED* = 0x0001
  CO_NEWLOCALS* = 0x0002
  CO_VARARGS* = 0x0004
  CO_VARKEYWORDS* = 0x0008

type                          # Rich comparison opcodes introduced in version 2.1
  TRichComparisonOpcode* = enum
    pyLT, pyLE, pyEQ, pyNE, pyGT, pyGE

const
  Py_TPFLAGS_HAVE_GETCHARBUFFER* = (1 shl 0) # PySequenceMethods contains sq_contains
  Py_TPFLAGS_HAVE_SEQUENCE_IN* = (1 shl 1) # Objects which participate in garbage collection (see objimp.h)
  Py_TPFLAGS_GC* = (1 shl 2)  # PySequenceMethods and PyNumberMethods contain in-place operators
  Py_TPFLAGS_HAVE_INPLACEOPS* = (1 shl 3) # PyNumberMethods do their own coercion */
  Py_TPFLAGS_CHECKTYPES* = (1 shl 4)
  Py_TPFLAGS_HAVE_RICHCOMPARE* = (1 shl 5) # Objects which are weakly referencable if their tp_weaklistoffset is >0
                                           # XXX Should this have the same value as Py_TPFLAGS_HAVE_RICHCOMPARE?
                                           # These both indicate a feature that appeared in the same alpha release.
  Py_TPFLAGS_HAVE_WEAKREFS* = (1 shl 6) # tp_iter is defined
  Py_TPFLAGS_HAVE_ITER* = (1 shl 7) # New members introduced by Python 2.2 exist
  Py_TPFLAGS_HAVE_CLASS* = (1 shl 8) # Set if the type object is dynamically allocated
  Py_TPFLAGS_HEAPTYPE* = (1 shl 9) # Set if the type allows subclassing
  Py_TPFLAGS_BASETYPE* = (1 shl 10) # Set if the type is 'ready' -- fully initialized
  Py_TPFLAGS_READY* = (1 shl 12) # Set while the type is being 'readied', to prevent recursive ready calls
  Py_TPFLAGS_READYING* = (1 shl 13) # Objects support garbage collection (see objimp.h)
  Py_TPFLAGS_HAVE_GC* = (1 shl 14)
  Py_TPFLAGS_DEFAULT* = Py_TPFLAGS_HAVE_GETCHARBUFFER or
      Py_TPFLAGS_HAVE_SEQUENCE_IN or Py_TPFLAGS_HAVE_INPLACEOPS or
      Py_TPFLAGS_HAVE_RICHCOMPARE or Py_TPFLAGS_HAVE_WEAKREFS or
      Py_TPFLAGS_HAVE_ITER or Py_TPFLAGS_HAVE_CLASS

type
  TPFlag* = enum
    tpfHaveGetCharBuffer, tpfHaveSequenceIn, tpfGC, tpfHaveInplaceOps,
    tpfCheckTypes, tpfHaveRichCompare, tpfHaveWeakRefs, tpfHaveIter,
    tpfHaveClass, tpfHeapType, tpfBaseType, tpfReady, tpfReadying, tpfHaveGC
  TPFlags* = set[TPFlag]

const
  TPFLAGS_DEFAULT* = {tpfHaveGetCharBuffer, tpfHaveSequenceIn,
    tpfHaveInplaceOps, tpfHaveRichCompare, tpfHaveWeakRefs, tpfHaveIter,
    tpfHaveClass}

const # Python opcodes
  single_input* = 256
  file_input* = 257
  eval_input* = 258
  funcdef* = 259
  parameters* = 260
  varargslist* = 261
  fpdef* = 262
  fplist* = 263
  stmt* = 264
  simple_stmt* = 265
  small_stmt* = 266
  expr_stmt* = 267
  augassign* = 268
  print_stmt* = 269
  del_stmt* = 270
  pass_stmt* = 271
  flow_stmt* = 272
  break_stmt* = 273
  continue_stmt* = 274
  return_stmt* = 275
  raise_stmt* = 276
  import_stmt* = 277
  import_as_name* = 278
  dotted_as_name* = 279
  dotted_name* = 280
  global_stmt* = 281
  exec_stmt* = 282
  assert_stmt* = 283
  compound_stmt* = 284
  if_stmt* = 285
  while_stmt* = 286
  for_stmt* = 287
  try_stmt* = 288
  except_clause* = 289
  suite* = 290
  test* = 291
  and_test* = 291
  not_test* = 293
  comparison* = 294
  comp_op* = 295
  expr* = 296
  xor_expr* = 297
  and_expr* = 298
  shift_expr* = 299
  arith_expr* = 300
  term* = 301
  factor* = 302
  power* = 303
  atom* = 304
  listmaker* = 305
  lambdef* = 306
  trailer* = 307
  subscriptlist* = 308
  subscript* = 309
  sliceop* = 310
  exprlist* = 311
  testlist* = 312
  dictmaker* = 313
  classdef* = 314
  arglist* = 315
  argument* = 316
  list_iter* = 317
  list_for* = 318
  list_if* = 319

const
  T_SHORT* = 0
  T_INT* = 1
  T_LONG* = 2
  T_FLOAT* = 3
  T_DOUBLE* = 4
  T_STRING* = 5
  T_OBJECT* = 6
  T_CHAR* = 7                 # 1-character string
  T_BYTE* = 8                 # 8-bit signed int
  T_UBYTE* = 9
  T_USHORT* = 10
  T_UINT* = 11
  T_ULONG* = 12
  T_STRING_INPLACE* = 13
  T_OBJECT_EX* = 16
  READONLY* = 1
  RO* = READONLY              # Shorthand
  READ_RESTRICTED* = 2
  WRITE_RESTRICTED* = 4
  RESTRICTED* = (READ_RESTRICTED or WRITE_RESTRICTED)

type
  TPyMemberType* = enum
    mtShort, mtInt, mtLong, mtFloat, mtDouble, mtString, mtObject, mtChar,
    mtByte, mtUByte, mtUShort, mtUInt, mtULong, mtStringInplace, mtObjectEx
  TPyMemberFlag* = enum
    mfDefault, mfReadOnly, mfReadRestricted, mfWriteRestricted, mfRestricted

type
  PInt* = ptr int

#  PLong* = ptr int32
#  PFloat* = ptr float32
#  PShort* = ptr int8

type
  PP_frozen* = ptr Pfrozen
  P_frozen* = ptr Tfrozen
  PPyObject* = ptr TPyObject
  PPPyObject* = ptr PPyObject
  PPPPyObject* = ptr PPPyObject
  PPyIntObject* = ptr TPyIntObject
  PPyTypeObject* = ptr TPyTypeObject
  PPySliceObject* = ptr TPySliceObject
  TPyCFunction* = proc (self, args: PPyObject): PPyObject{.cdecl.}
  Tunaryfunc* = proc (ob1: PPyObject): PPyObject{.cdecl.}
  Tbinaryfunc* = proc (ob1, ob2: PPyObject): PPyObject{.cdecl.}
  Tternaryfunc* = proc (ob1, ob2, ob3: PPyObject): PPyObject{.cdecl.}
  Tinquiry* = proc (ob1: PPyObject): int{.cdecl.}
  Tcoercion* = proc (ob1, ob2: PPPyObject): int{.cdecl.}
  Tintargfunc* = proc (ob1: PPyObject, i: int): PPyObject{.cdecl.}
  Tintintargfunc* = proc (ob1: PPyObject, i1, i2: int): PPyObject{.cdecl.}
  Tintobjargproc* = proc (ob1: PPyObject, i: int, ob2: PPyObject): int{.cdecl.}
  Tintintobjargproc* = proc (ob1: PPyObject, i1, i2: int, ob2: PPyObject): int{.
      cdecl.}
  Tobjobjargproc* = proc (ob1, ob2, ob3: PPyObject): int{.cdecl.}
  Tpydestructor* = proc (ob: PPyObject){.cdecl.}
  Tprintfunc* = proc (ob: PPyObject, f: TFile, i: int): int{.cdecl.}
  Tgetattrfunc* = proc (ob1: PPyObject, name: cstring): PPyObject{.cdecl.}
  Tsetattrfunc* = proc (ob1: PPyObject, name: cstring, ob2: PPyObject): int{.
      cdecl.}
  Tcmpfunc* = proc (ob1, ob2: PPyObject): int{.cdecl.}
  Treprfunc* = proc (ob: PPyObject): PPyObject{.cdecl.}
  Thashfunc* = proc (ob: PPyObject): int32{.cdecl.}
  Tgetattrofunc* = proc (ob1, ob2: PPyObject): PPyObject{.cdecl.}
  Tsetattrofunc* = proc (ob1, ob2, ob3: PPyObject): int{.cdecl.}
  Tgetreadbufferproc* = proc (ob1: PPyObject, i: int, p: Pointer): int{.cdecl.}
  Tgetwritebufferproc* = proc (ob1: PPyObject, i: int, p: Pointer): int{.cdecl.}
  Tgetsegcountproc* = proc (ob1: PPyObject, i: int): int{.cdecl.}
  Tgetcharbufferproc* = proc (ob1: PPyObject, i: int, pstr: cstring): int{.cdecl.}
  Tobjobjproc* = proc (ob1, ob2: PPyObject): int{.cdecl.}
  Tvisitproc* = proc (ob1: PPyObject, p: Pointer): int{.cdecl.}
  Ttraverseproc* = proc (ob1: PPyObject, prc: TVisitproc, p: Pointer): int{.
      cdecl.}
  Trichcmpfunc* = proc (ob1, ob2: PPyObject, i: int): PPyObject{.cdecl.}
  Tgetiterfunc* = proc (ob1: PPyObject): PPyObject{.cdecl.}
  Titernextfunc* = proc (ob1: PPyObject): PPyObject{.cdecl.}
  Tdescrgetfunc* = proc (ob1, ob2, ob3: PPyObject): PPyObject{.cdecl.}
  Tdescrsetfunc* = proc (ob1, ob2, ob3: PPyObject): int{.cdecl.}
  Tinitproc* = proc (self, args, kwds: PPyObject): int{.cdecl.}
  Tnewfunc* = proc (subtype: PPyTypeObject, args, kwds: PPyObject): PPyObject{.
      cdecl.}
  Tallocfunc* = proc (self: PPyTypeObject, nitems: int): PPyObject{.cdecl.}
  TPyNumberMethods*{.final.} = object
    nb_add*: Tbinaryfunc
    nb_substract*: Tbinaryfunc
    nb_multiply*: Tbinaryfunc
    nb_divide*: Tbinaryfunc
    nb_remainder*: Tbinaryfunc
    nb_divmod*: Tbinaryfunc
    nb_power*: Tternaryfunc
    nb_negative*: Tunaryfunc
    nb_positive*: Tunaryfunc
    nb_absolute*: Tunaryfunc
    nb_nonzero*: Tinquiry
    nb_invert*: Tunaryfunc
    nb_lshift*: Tbinaryfunc
    nb_rshift*: Tbinaryfunc
    nb_and*: Tbinaryfunc
    nb_xor*: Tbinaryfunc
    nb_or*: Tbinaryfunc
    nb_coerce*: Tcoercion
    nb_int*: Tunaryfunc
    nb_long*: Tunaryfunc
    nb_float*: Tunaryfunc
    nb_oct*: Tunaryfunc
    nb_hex*: Tunaryfunc       #/ jah 29-sep-2000: updated for python 2.0
                              #/                   added from .h
    nb_inplace_add*: Tbinaryfunc
    nb_inplace_subtract*: Tbinaryfunc
    nb_inplace_multiply*: Tbinaryfunc
    nb_inplace_divide*: Tbinaryfunc
    nb_inplace_remainder*: Tbinaryfunc
    nb_inplace_power*: Tternaryfunc
    nb_inplace_lshift*: Tbinaryfunc
    nb_inplace_rshift*: Tbinaryfunc
    nb_inplace_and*: Tbinaryfunc
    nb_inplace_xor*: Tbinaryfunc
    nb_inplace_or*: Tbinaryfunc # Added in release 2.2
                                # The following require the Py_TPFLAGS_HAVE_CLASS flag
    nb_floor_divide*: Tbinaryfunc
    nb_true_divide*: Tbinaryfunc
    nb_inplace_floor_divide*: Tbinaryfunc
    nb_inplace_true_divide*: Tbinaryfunc

  PPyNumberMethods* = ptr TPyNumberMethods
  TPySequenceMethods*{.final.} = object
    sq_length*: Tinquiry
    sq_concat*: Tbinaryfunc
    sq_repeat*: Tintargfunc
    sq_item*: Tintargfunc
    sq_slice*: Tintintargfunc
    sq_ass_item*: Tintobjargproc
    sq_ass_slice*: Tintintobjargproc
    sq_contains*: Tobjobjproc
    sq_inplace_concat*: Tbinaryfunc
    sq_inplace_repeat*: Tintargfunc

  PPySequenceMethods* = ptr TPySequenceMethods
  TPyMappingMethods*{.final.} = object
    mp_length*: Tinquiry
    mp_subscript*: Tbinaryfunc
    mp_ass_subscript*: Tobjobjargproc

  PPyMappingMethods* = ptr TPyMappingMethods
  TPyBufferProcs*{.final.} = object
    bf_getreadbuffer*: Tgetreadbufferproc
    bf_getwritebuffer*: Tgetwritebufferproc
    bf_getsegcount*: Tgetsegcountproc
    bf_getcharbuffer*: Tgetcharbufferproc

  PPyBufferProcs* = ptr TPyBufferProcs
  TPy_complex*{.final.} = object
    float*: float64
    imag*: float64

  TPyObject*{.pure, inheritable.} = object
    ob_refcnt*: int
    ob_type*: PPyTypeObject

  TPyIntObject* = object of TPyObject
    ob_ival*: int32

  PByte* = ptr int8
  Tfrozen*{.final.} = object
    name*: cstring
    code*: PByte
    size*: int

  TPySliceObject* = object of TPyObject
    start*, stop*, step*: PPyObject

  PPyMethodDef* = ptr TPyMethodDef
  TPyMethodDef*{.final.} = object  # structmember.h
    ml_name*: cstring
    ml_meth*: TPyCFunction
    ml_flags*: int
    ml_doc*: cstring

  PPyMemberDef* = ptr TPyMemberDef
  TPyMemberDef*{.final.} = object  # descrobject.h
                                   # Descriptors
    name*: cstring
    theType*: int
    offset*: int
    flags*: int
    doc*: cstring

  Tgetter* = proc (obj: PPyObject, context: Pointer): PPyObject{.cdecl.}
  Tsetter* = proc (obj, value: PPyObject, context: Pointer): int{.cdecl.}
  PPyGetSetDef* = ptr TPyGetSetDef
  TPyGetSetDef*{.final.} = object
    name*: cstring
    get*: Tgetter
    setter*: Tsetter
    doc*: cstring
    closure*: Pointer

  Twrapperfunc* = proc (self, args: PPyObject, wrapped: Pointer): PPyObject{.
      cdecl.}
  pwrapperbase* = ptr Twrapperbase
  Twrapperbase*{.final.} = object  # Various kinds of descriptor objects
                                   ##define PyDescr_COMMON \
                                   #          PyObject_HEAD \
                                   #          PyTypeObject *d_type; \
                                   #          PyObject *d_name
                                   #
    name*: cstring
    wrapper*: Twrapperfunc
    doc*: cstring

  PPyDescrObject* = ptr TPyDescrObject
  TPyDescrObject* = object of TPyObject
    d_type*: PPyTypeObject
    d_name*: PPyObject

  PPyMethodDescrObject* = ptr TPyMethodDescrObject
  TPyMethodDescrObject* = object of TPyDescrObject
    d_method*: PPyMethodDef

  PPyMemberDescrObject* = ptr TPyMemberDescrObject
  TPyMemberDescrObject* = object of TPyDescrObject
    d_member*: PPyMemberDef

  PPyGetSetDescrObject* = ptr TPyGetSetDescrObject
  TPyGetSetDescrObject* = object of TPyDescrObject
    d_getset*: PPyGetSetDef

  PPyWrapperDescrObject* = ptr TPyWrapperDescrObject
  TPyWrapperDescrObject* = object of TPyDescrObject # object.h
    d_base*: pwrapperbase
    d_wrapped*: Pointer       # This can be any function pointer

  TPyTypeObject* = object of TPyObject
    ob_size*: int             # Number of items in variable part
    tp_name*: cstring         # For printing
    tp_basicsize*, tp_itemsize*: int # For allocation
                                     # Methods to implement standard operations
    tp_dealloc*: Tpydestructor
    tp_print*: Tprintfunc
    tp_getattr*: Tgetattrfunc
    tp_setattr*: Tsetattrfunc
    tp_compare*: Tcmpfunc
    tp_repr*: Treprfunc       # Method suites for standard classes
    tp_as_number*: PPyNumberMethods
    tp_as_sequence*: PPySequenceMethods
    tp_as_mapping*: PPyMappingMethods # More standard operations (here for binary compatibility)
    tp_hash*: Thashfunc
    tp_call*: Tternaryfunc
    tp_str*: Treprfunc
    tp_getattro*: Tgetattrofunc
    tp_setattro*: Tsetattrofunc #/ jah 29-sep-2000: updated for python 2.0
                                # Functions to access object as input/output buffer
    tp_as_buffer*: PPyBufferProcs # Flags to define presence of optional/expanded features
    tp_flags*: int32
    tp_doc*: cstring          # Documentation string
                              # call function for all accessible objects
    tp_traverse*: Ttraverseproc # delete references to contained objects
    tp_clear*: Tinquiry       # rich comparisons
    tp_richcompare*: Trichcmpfunc # weak reference enabler
    tp_weaklistoffset*: int32 # Iterators
    tp_iter*: Tgetiterfunc
    tp_iternext*: Titernextfunc # Attribute descriptor and subclassing stuff
    tp_methods*: PPyMethodDef
    tp_members*: PPyMemberDef
    tp_getset*: PPyGetSetDef
    tp_base*: PPyTypeObject
    tp_dict*: PPyObject
    tp_descr_get*: Tdescrgetfunc
    tp_descr_set*: Tdescrsetfunc
    tp_dictoffset*: int32
    tp_init*: Tinitproc
    tp_alloc*: Tallocfunc
    tp_new*: Tnewfunc
    tp_free*: Tpydestructor   # Low-level free-memory routine
    tp_is_gc*: Tinquiry       # For PyObject_IS_GC
    tp_bases*: PPyObject
    tp_mro*: PPyObject        # method resolution order
    tp_cache*: PPyObject
    tp_subclasses*: PPyObject
    tp_weaklist*: PPyObject   #More spares
    tp_xxx7*: pointer
    tp_xxx8*: pointer

  PPyMethodChain* = ptr TPyMethodChain
  TPyMethodChain*{.final.} = object
    methods*: PPyMethodDef
    link*: PPyMethodChain

  PPyClassObject* = ptr TPyClassObject
  TPyClassObject* = object of TPyObject
    cl_bases*: PPyObject      # A tuple of class objects
    cl_dict*: PPyObject       # A dictionary
    cl_name*: PPyObject       # A string
                              # The following three are functions or NULL
    cl_getattr*: PPyObject
    cl_setattr*: PPyObject
    cl_delattr*: PPyObject

  PPyInstanceObject* = ptr TPyInstanceObject
  TPyInstanceObject* = object of TPyObject
    in_class*: PPyClassObject # The class object
    in_dict*: PPyObject       # A dictionary

  PPyMethodObject* = ptr TPyMethodObject
  TPyMethodObject* = object of TPyObject # Bytecode object, compile.h
    im_func*: PPyObject       # The function implementing the method
    im_self*: PPyObject       # The instance it is bound to, or NULL
    im_class*: PPyObject      # The class that defined the method

  PPyCodeObject* = ptr TPyCodeObject
  TPyCodeObject* = object of TPyObject # from pystate.h
    co_argcount*: int         # #arguments, except *args
    co_nlocals*: int          # #local variables
    co_stacksize*: int        # #entries needed for evaluation stack
    co_flags*: int            # CO_..., see below
    co_code*: PPyObject       # instruction opcodes (it hides a PyStringObject)
    co_consts*: PPyObject     # list (constants used)
    co_names*: PPyObject      # list of strings (names used)
    co_varnames*: PPyObject   # tuple of strings (local variable names)
    co_freevars*: PPyObject   # tuple of strings (free variable names)
    co_cellvars*: PPyObject   # tuple of strings (cell variable names)
                              # The rest doesn't count for hash/cmp
    co_filename*: PPyObject   # string (where it was loaded from)
    co_name*: PPyObject       # string (name, for reference)
    co_firstlineno*: int      # first source line number
    co_lnotab*: PPyObject     # string (encoding addr<->lineno mapping)

  PPyInterpreterState* = ptr TPyInterpreterState
  PPyThreadState* = ptr TPyThreadState
  PPyFrameObject* = ptr TPyFrameObject # Interpreter environments
  TPyInterpreterState*{.final.} = object  # Thread specific information
    next*: PPyInterpreterState
    tstate_head*: PPyThreadState
    modules*: PPyObject
    sysdict*: PPyObject
    builtins*: PPyObject
    checkinterval*: int

  TPyThreadState*{.final.} = object  # from frameobject.h
    next*: PPyThreadState
    interp*: PPyInterpreterState
    frame*: PPyFrameObject
    recursion_depth*: int
    ticker*: int
    tracing*: int
    sys_profilefunc*: PPyObject
    sys_tracefunc*: PPyObject
    curexc_type*: PPyObject
    curexc_value*: PPyObject
    curexc_traceback*: PPyObject
    exc_type*: PPyObject
    exc_value*: PPyObject
    exc_traceback*: PPyObject
    dict*: PPyObject

  PPyTryBlock* = ptr TPyTryBlock
  TPyTryBlock*{.final.} = object
    b_type*: int              # what kind of block this is
    b_handler*: int           # where to jump to find handler
    b_level*: int             # value stack level to pop to

  CO_MAXBLOCKS* = range[0..19]
  TPyFrameObject* = object of TPyObject # start of the VAR_HEAD of an object
                                        # From traceback.c
    ob_size*: int             # Number of items in variable part
                              # End of the Head of an object
    f_back*: PPyFrameObject   # previous frame, or NULL
    f_code*: PPyCodeObject    # code segment
    f_builtins*: PPyObject    # builtin symbol table (PyDictObject)
    f_globals*: PPyObject     # global symbol table (PyDictObject)
    f_locals*: PPyObject      # local symbol table (PyDictObject)
    f_valuestack*: PPPyObject # points after the last local
                              # Next free slot in f_valuestack. Frame creation sets to f_valuestack.
                              # Frame evaluation usually NULLs it, but a frame that yields sets it
                              # to the current stack top.
    f_stacktop*: PPPyObject
    f_trace*: PPyObject       # Trace function
    f_exc_type*, f_exc_value*, f_exc_traceback*: PPyObject
    f_tstate*: PPyThreadState
    f_lasti*: int             # Last instruction if called
    f_lineno*: int            # Current line number
    f_restricted*: int        # Flag set if restricted operations
                              # in this scope
    f_iblock*: int            # index in f_blockstack
    f_blockstack*: array[CO_MAXBLOCKS, TPyTryBlock] # for try and loop blocks
    f_nlocals*: int           # number of locals
    f_ncells*: int
    f_nfreevars*: int
    f_stacksize*: int         # size of value stack
    f_localsplus*: array[0..0, PPyObject] # locals+stack, dynamically sized

  PPyTraceBackObject* = ptr TPyTraceBackObject
  TPyTraceBackObject* = object of TPyObject # Parse tree node interface
    tb_next*: PPyTraceBackObject
    tb_frame*: PPyFrameObject
    tb_lasti*: int
    tb_lineno*: int

  PNode* = ptr Tnode
  Tnode*{.final.} = object    # From weakrefobject.h
    n_type*: int16
    n_str*: cstring
    n_lineno*: int16
    n_nchildren*: int16
    n_child*: PNode

  PPyWeakReference* = ptr TPyWeakReference
  TPyWeakReference* = object of TPyObject
    wr_object*: PPyObject
    wr_callback*: PPyObject
    hash*: int32
    wr_prev*: PPyWeakReference
    wr_next*: PPyWeakReference


const
  PyDateTime_DATE_DATASIZE* = 4 # # of bytes for year, month, and day
  PyDateTime_TIME_DATASIZE* = 6 # # of bytes for hour, minute, second, and usecond
  PyDateTime_DATETIME_DATASIZE* = 10 # # of bytes for year, month,
                                     # day, hour, minute, second, and usecond.

type
  TPyDateTime_Delta* = object of TPyObject
    hashcode*: int            # -1 when unknown
    days*: int                # -MAX_DELTA_DAYS <= days <= MAX_DELTA_DAYS
    seconds*: int             # 0 <= seconds < 24*3600 is invariant
    microseconds*: int        # 0 <= microseconds < 1000000 is invariant

  PPyDateTime_Delta* = ptr TPyDateTime_Delta
  TPyDateTime_TZInfo* = object of TPyObject # a pure abstract base clase
  PPyDateTime_TZInfo* = ptr TPyDateTime_TZInfo
  TPyDateTime_BaseTZInfo* = object of TPyObject
    hashcode*: int
    hastzinfo*: bool          # boolean flag

  PPyDateTime_BaseTZInfo* = ptr TPyDateTime_BaseTZInfo
  TPyDateTime_BaseTime* = object of TPyDateTime_BaseTZInfo
    data*: array[0..Pred(PyDateTime_TIME_DATASIZE), int8]

  PPyDateTime_BaseTime* = ptr TPyDateTime_BaseTime
  TPyDateTime_Time* = object of TPyDateTime_BaseTime # hastzinfo true
    tzinfo*: PPyObject

  PPyDateTime_Time* = ptr TPyDateTime_Time
  TPyDateTime_Date* = object of TPyDateTime_BaseTZInfo
    data*: array[0..Pred(PyDateTime_DATE_DATASIZE), int8]

  PPyDateTime_Date* = ptr TPyDateTime_Date
  TPyDateTime_BaseDateTime* = object of TPyDateTime_BaseTZInfo
    data*: array[0..Pred(PyDateTime_DATETIME_DATASIZE), int8]

  PPyDateTime_BaseDateTime* = ptr TPyDateTime_BaseDateTime
  TPyDateTime_DateTime* = object of TPyDateTime_BaseTZInfo
    data*: array[0..Pred(PyDateTime_DATETIME_DATASIZE), int8]
    tzinfo*: PPyObject

  PPyDateTime_DateTime* = ptr TPyDateTime_DateTime

#----------------------------------------------------#
#                                                    #
#         New exception classes                      #
#                                                    #
#----------------------------------------------------#

#
#  // Python's exceptions
#  EPythonError   = object(Exception)
#      EName: String;
#      EValue: String;
#  end;
#  EPyExecError   = object(EPythonError)
#  end;
#
#  // Standard exception classes of Python
#
#/// jah 29-sep-2000: updated for python 2.0
#///                   base classes updated according python documentation
#
#{ Hierarchy of Python exceptions, Python 2.3, copied from <INSTALL>\Python\exceptions.c
#
#Exception\n\
# |\n\
# +-- SystemExit\n\
# +-- StopIteration\n\
# +-- StandardError\n\
# |    |\n\
# |    +-- KeyboardInterrupt\n\
# |    +-- ImportError\n\
# |    +-- EnvironmentError\n\
# |    |    |\n\
# |    |    +-- IOError\n\
# |    |    +-- OSError\n\
# |    |         |\n\
# |    |         +-- WindowsError\n\
# |    |         +-- VMSError\n\
# |    |\n\
# |    +-- EOFError\n\
# |    +-- RuntimeError\n\
# |    |    |\n\
# |    |    +-- NotImplementedError\n\
# |    |\n\
# |    +-- NameError\n\
# |    |    |\n\
# |    |    +-- UnboundLocalError\n\
# |    |\n\
# |    +-- AttributeError\n\
# |    +-- SyntaxError\n\
# |    |    |\n\
# |    |    +-- IndentationError\n\
# |    |         |\n\
# |    |         +-- TabError\n\
# |    |\n\
# |    +-- TypeError\n\
# |    +-- AssertionError\n\
# |    +-- LookupError\n\
# |    |    |\n\
# |    |    +-- IndexError\n\
# |    |    +-- KeyError\n\
# |    |\n\
# |    +-- ArithmeticError\n\
# |    |    |\n\
# |    |    +-- OverflowError\n\
# |    |    +-- ZeroDivisionError\n\
# |    |    +-- FloatingPointError\n\
# |    |\n\
# |    +-- ValueError\n\
# |    |    |\n\
# |    |    +-- UnicodeError\n\
# |    |        |\n\
# |    |        +-- UnicodeEncodeError\n\
# |    |        +-- UnicodeDecodeError\n\
# |    |        +-- UnicodeTranslateError\n\
# |    |\n\
# |    +-- ReferenceError\n\
# |    +-- SystemError\n\
# |    +-- MemoryError\n\
# |\n\
# +---Warning\n\
#      |\n\
#      +-- UserWarning\n\
#      +-- DeprecationWarning\n\
#      +-- PendingDeprecationWarning\n\
#      +-- SyntaxWarning\n\
#      +-- OverflowWarning\n\
#      +-- RuntimeWarning\n\
#      +-- FutureWarning"
#}
#   EPyException = class (EPythonError);
#   EPyStandardError = class (EPyException);
#   EPyArithmeticError = class (EPyStandardError);
#   EPyLookupError = class (EPyStandardError);
#   EPyAssertionError = class (EPyStandardError);
#   EPyAttributeError = class (EPyStandardError);
#   EPyEOFError = class (EPyStandardError);
#   EPyFloatingPointError = class (EPyArithmeticError);
#   EPyEnvironmentError = class (EPyStandardError);
#   EPyIOError = class (EPyEnvironmentError);
#   EPyOSError = class (EPyEnvironmentError);
#   EPyImportError = class (EPyStandardError);
#   EPyIndexError = class (EPyLookupError);
#   EPyKeyError = class (EPyLookupError);
#   EPyKeyboardInterrupt = class (EPyStandardError);
#   EPyMemoryError = class (EPyStandardError);
#   EPyNameError = class (EPyStandardError);
#   EPyOverflowError = class (EPyArithmeticError);
#   EPyRuntimeError = class (EPyStandardError);
#   EPyNotImplementedError = class (EPyRuntimeError);
#   EPySyntaxError = class (EPyStandardError)
#   public
#      EFileName: string;
#      ELineStr: string;
#      ELineNumber: Integer;
#      EOffset: Integer;
#   end;
#   EPyIndentationError = class (EPySyntaxError);
#   EPyTabError = class (EPyIndentationError);
#   EPySystemError = class (EPyStandardError);
#   EPySystemExit = class (EPyException);
#   EPyTypeError = class (EPyStandardError);
#   EPyUnboundLocalError = class (EPyNameError);
#   EPyValueError = class (EPyStandardError);
#   EPyUnicodeError = class (EPyValueError);
#   UnicodeEncodeError = class (EPyUnicodeError);
#   UnicodeDecodeError = class (EPyUnicodeError);
#   UnicodeTranslateError = class (EPyUnicodeError);
#   EPyZeroDivisionError = class (EPyArithmeticError);
#   EPyStopIteration = class(EPyException);
#   EPyWarning = class (EPyException);
#   EPyUserWarning = class (EPyWarning);
#   EPyDeprecationWarning = class (EPyWarning);
#   PendingDeprecationWarning = class (EPyWarning);
#   FutureWarning = class (EPyWarning);
#   EPySyntaxWarning = class (EPyWarning);
#   EPyOverflowWarning = class (EPyWarning);
#   EPyRuntimeWarning = class (EPyWarning);
#   EPyReferenceError = class (EPyStandardError);
#

var
  PyArg_Parse*: proc (args: PPyObject, format: cstring): int{.cdecl, varargs.}
  PyArg_ParseTuple*: proc (args: PPyObject, format: cstring, x1: Pointer = nil,
                           x2: Pointer = nil, x3: Pointer = nil): int{.cdecl, varargs.}
  Py_BuildValue*: proc (format: cstring): PPyObject{.cdecl, varargs.}
  PyCode_Addr2Line*: proc (co: PPyCodeObject, addrq: int): int{.cdecl.}
  DLL_Py_GetBuildInfo*: proc (): cstring{.cdecl.}

var
  Py_DebugFlag*: PInt
  Py_VerboseFlag*: PInt
  Py_InteractiveFlag*: PInt
  Py_OptimizeFlag*: PInt
  Py_NoSiteFlag*: PInt
  Py_UseClassExceptionsFlag*: PInt
  Py_FrozenFlag*: PInt
  Py_TabcheckFlag*: PInt
  Py_UnicodeFlag*: PInt
  Py_IgnoreEnvironmentFlag*: PInt
  Py_DivisionWarningFlag*: PInt
  #_PySys_TraceFunc:    PPPyObject;
  #_PySys_ProfileFunc: PPPPyObject;
  PyImport_FrozenModules*: PP_frozen
  Py_None*: PPyObject
  Py_Ellipsis*: PPyObject
  Py_False*: PPyIntObject
  Py_True*: PPyIntObject
  Py_NotImplemented*: PPyObject
  PyExc_AttributeError*: PPPyObject
  PyExc_EOFError*: PPPyObject
  PyExc_IOError*: PPPyObject
  PyExc_ImportError*: PPPyObject
  PyExc_IndexError*: PPPyObject
  PyExc_KeyError*: PPPyObject
  PyExc_KeyboardInterrupt*: PPPyObject
  PyExc_MemoryError*: PPPyObject
  PyExc_NameError*: PPPyObject
  PyExc_OverflowError*: PPPyObject
  PyExc_RuntimeError*: PPPyObject
  PyExc_SyntaxError*: PPPyObject
  PyExc_SystemError*: PPPyObject
  PyExc_SystemExit*: PPPyObject
  PyExc_TypeError*: PPPyObject
  PyExc_ValueError*: PPPyObject
  PyExc_ZeroDivisionError*: PPPyObject
  PyExc_ArithmeticError*: PPPyObject
  PyExc_Exception*: PPPyObject
  PyExc_FloatingPointError*: PPPyObject
  PyExc_LookupError*: PPPyObject
  PyExc_StandardError*: PPPyObject
  PyExc_AssertionError*: PPPyObject
  PyExc_EnvironmentError*: PPPyObject
  PyExc_IndentationError*: PPPyObject
  PyExc_MemoryErrorInst*: PPPyObject
  PyExc_NotImplementedError*: PPPyObject
  PyExc_OSError*: PPPyObject
  PyExc_TabError*: PPPyObject
  PyExc_UnboundLocalError*: PPPyObject
  PyExc_UnicodeError*: PPPyObject
  PyExc_Warning*: PPPyObject
  PyExc_DeprecationWarning*: PPPyObject
  PyExc_RuntimeWarning*: PPPyObject
  PyExc_SyntaxWarning*: PPPyObject
  PyExc_UserWarning*: PPPyObject
  PyExc_OverflowWarning*: PPPyObject
  PyExc_ReferenceError*: PPPyObject
  PyExc_StopIteration*: PPPyObject
  PyExc_FutureWarning*: PPPyObject
  PyExc_PendingDeprecationWarning*: PPPyObject
  PyExc_UnicodeDecodeError*: PPPyObject
  PyExc_UnicodeEncodeError*: PPPyObject
  PyExc_UnicodeTranslateError*: PPPyObject
  PyType_Type*: PPyTypeObject
  PyCFunction_Type*: PPyTypeObject
  PyCObject_Type*: PPyTypeObject
  PyClass_Type*: PPyTypeObject
  PyCode_Type*: PPyTypeObject
  PyComplex_Type*: PPyTypeObject
  PyDict_Type*: PPyTypeObject
  PyFile_Type*: PPyTypeObject
  PyFloat_Type*: PPyTypeObject
  PyFrame_Type*: PPyTypeObject
  PyFunction_Type*: PPyTypeObject
  PyInstance_Type*: PPyTypeObject
  PyInt_Type*: PPyTypeObject
  PyList_Type*: PPyTypeObject
  PyLong_Type*: PPyTypeObject
  PyMethod_Type*: PPyTypeObject
  PyModule_Type*: PPyTypeObject
  PyObject_Type*: PPyTypeObject
  PyRange_Type*: PPyTypeObject
  PySlice_Type*: PPyTypeObject
  PyString_Type*: PPyTypeObject
  PyTuple_Type*: PPyTypeObject
  PyBaseObject_Type*: PPyTypeObject
  PyBuffer_Type*: PPyTypeObject
  PyCallIter_Type*: PPyTypeObject
  PyCell_Type*: PPyTypeObject
  PyClassMethod_Type*: PPyTypeObject
  PyProperty_Type*: PPyTypeObject
  PySeqIter_Type*: PPyTypeObject
  PyStaticMethod_Type*: PPyTypeObject
  PySuper_Type*: PPyTypeObject
  PySymtableEntry_Type*: PPyTypeObject
  PyTraceBack_Type*: PPyTypeObject
  PyUnicode_Type*: PPyTypeObject
  PyWrapperDescr_Type*: PPyTypeObject
  PyBaseString_Type*: PPyTypeObject
  PyBool_Type*: PPyTypeObject
  PyEnum_Type*: PPyTypeObject

  #PyArg_GetObject: proc(args: PPyObject; nargs, i: integer; p_a: PPPyObject): integer; cdecl;
  #PyArg_GetLong: proc(args: PPyObject; nargs, i: integer; p_a: PLong): integer; cdecl;
  #PyArg_GetShort: proc(args: PPyObject; nargs, i: integer; p_a: PShort): integer; cdecl;
  #PyArg_GetFloat: proc(args: PPyObject; nargs, i: integer; p_a: PFloat): integer; cdecl;
  #PyArg_GetString: proc(args: PPyObject; nargs, i: integer; p_a: PString): integer; cdecl;
  #PyArgs_VaParse:  proc (args: PPyObject; format: PChar;
  #                          va_list: array of const): integer; cdecl;
  # Does not work!
  # Py_VaBuildValue: proc (format: PChar; va_list: array of const): PPyObject; cdecl;
  #PyBuiltin_Init: proc; cdecl;
proc PyComplex_FromCComplex*(c: TPy_complex): PPyObject{.cdecl, importc, dynlib: dllname.}
proc PyComplex_FromDoubles*(realv, imag: float64): PPyObject{.cdecl, importc, dynlib: dllname.}
proc PyComplex_RealAsDouble*(op: PPyObject): float64{.cdecl, importc, dynlib: dllname.}
proc PyComplex_ImagAsDouble*(op: PPyObject): float64{.cdecl, importc, dynlib: dllname.}
proc PyComplex_AsCComplex*(op: PPyObject): TPy_complex{.cdecl, importc, dynlib: dllname.}
proc PyCFunction_GetFunction*(ob: PPyObject): Pointer{.cdecl, importc, dynlib: dllname.}
proc PyCFunction_GetSelf*(ob: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.}
proc PyCallable_Check*(ob: PPyObject): int{.cdecl, importc, dynlib: dllname.}
proc PyCObject_FromVoidPtr*(cobj, destruct: Pointer): PPyObject{.cdecl, importc, dynlib: dllname.}
proc PyCObject_AsVoidPtr*(ob: PPyObject): Pointer{.cdecl, importc, dynlib: dllname.}
proc PyClass_New*(ob1, ob2, ob3: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.}
proc PyClass_IsSubclass*(ob1, ob2: PPyObject): int{.cdecl, importc, dynlib: dllname.}
proc Py_InitModule4*(name: cstring, methods: PPyMethodDef, doc: cstring,
                         passthrough: PPyObject, Api_Version: int): PPyObject{.
      cdecl, importc, dynlib: dllname.}
proc PyErr_BadArgument*(): int{.cdecl, importc, dynlib: dllname.}
proc PyErr_BadInternalCall*(){.cdecl, importc, dynlib: dllname.}
proc PyErr_CheckSignals*(): int{.cdecl, importc, dynlib: dllname.}
proc PyErr_Clear*(){.cdecl, importc, dynlib: dllname.}
proc PyErr_Fetch*(errtype, errvalue, errtraceback: PPPyObject){.cdecl, importc, dynlib: dllname.}
proc PyErr_NoMemory*(): PPyObject{.cdecl, importc, dynlib: dllname.}
proc PyErr_Occurred*(): PPyObject{.cdecl, importc, dynlib: dllname.}
proc PyErr_Print*(){.cdecl, importc, dynlib: dllname.}
proc PyErr_Restore*(errtype, errvalue, errtraceback: PPyObject){.cdecl, importc, dynlib: dllname.}
proc PyErr_SetFromErrno*(ob: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.}
proc PyErr_SetNone*(value: PPyObject){.cdecl, importc, dynlib: dllname.}
proc PyErr_SetObject*(ob1, ob2: PPyObject){.cdecl, importc, dynlib: dllname.}
proc PyErr_SetString*(ErrorObject: PPyObject, text: cstring){.cdecl, importc, dynlib: dllname.}
proc PyImport_GetModuleDict*(): PPyObject{.cdecl, importc, dynlib: dllname.}
proc PyInt_FromLong*(x: int32): PPyObject{.cdecl, importc, dynlib: dllname.}
proc Py_Initialize*(){.cdecl, importc, dynlib: dllname.}
proc Py_Exit*(RetVal: int){.cdecl, importc, dynlib: dllname.}
proc PyEval_GetBuiltins*(): PPyObject{.cdecl, importc, dynlib: dllname.}
proc PyDict_GetItem*(mp, key: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.}
proc PyDict_SetItem*(mp, key, item: PPyObject): int{.cdecl, importc, dynlib: dllname.}
proc PyDict_DelItem*(mp, key: PPyObject): int{.cdecl, importc, dynlib: dllname.}
proc PyDict_Clear*(mp: PPyObject){.cdecl, importc, dynlib: dllname.}
proc PyDict_Next*(mp: PPyObject, pos: PInt, key, value: PPPyObject): int{.
      cdecl, importc, dynlib: dllname.}
proc PyDict_Keys*(mp: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.}
proc PyDict_Values*(mp: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.}
proc PyDict_Items*(mp: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.}
proc PyDict_Size*(mp: PPyObject): int{.cdecl, importc, dynlib: dllname.}
proc PyDict_DelItemString*(dp: PPyObject, key: cstring): int{.cdecl, importc, dynlib: dllname.}
proc PyDict_New*(): PPyObject{.cdecl, importc, dynlib: dllname.}
proc PyDict_GetItemString*(dp: PPyObject, key: cstring): PPyObject{.cdecl, importc, dynlib: dllname.}
proc PyDict_SetItemString*(dp: PPyObject, key: cstring, item: PPyObject): int{.
      cdecl, importc, dynlib: dllname.}
proc PyDictProxy_New*(obj: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.}
proc PyModule_GetDict*(module: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.}
proc PyObject_Str*(v: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.}
proc PyRun_String*(str: cstring, start: int, globals: PPyObject,
                       locals: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.}
proc PyRun_SimpleString*(str: cstring): int{.cdecl, importc, dynlib: dllname.}
proc PyString_AsString*(ob: PPyObject): cstring{.cdecl, importc, dynlib: dllname.}
proc PyString_FromString*(str: cstring): PPyObject{.cdecl, importc, dynlib: dllname.}
proc PySys_SetArgv*(argc: int, argv: cstringArray){.cdecl, importc, dynlib: dllname.}
  #+ means, Grzegorz or me has tested his non object version of this function
  #+
proc PyCFunction_New*(md: PPyMethodDef, ob: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #+
proc PyEval_CallObject*(ob1, ob2: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyEval_CallObjectWithKeywords*(ob1, ob2, ob3: PPyObject): PPyObject{.
      cdecl, importc, dynlib: dllname.}                 #-
proc PyEval_GetFrame*(): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyEval_GetGlobals*(): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyEval_GetLocals*(): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyEval_GetOwner*(): PPyObject {.cdecl, importc, dynlib: dllname.}
proc PyEval_GetRestricted*(): int{.cdecl, importc, dynlib: dllname.} #-
proc PyEval_InitThreads*(){.cdecl, importc, dynlib: dllname.} #-
proc PyEval_RestoreThread*(tstate: PPyThreadState){.cdecl, importc, dynlib: dllname.} #-
proc PyEval_SaveThread*(): PPyThreadState{.cdecl, importc, dynlib: dllname.} #-
proc PyFile_FromString*(pc1, pc2: cstring): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyFile_GetLine*(ob: PPyObject, i: int): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyFile_Name*(ob: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyFile_SetBufSize*(ob: PPyObject, i: int){.cdecl, importc, dynlib: dllname.} #-
proc PyFile_SoftSpace*(ob: PPyObject, i: int): int{.cdecl, importc, dynlib: dllname.} #-
proc PyFile_WriteObject*(ob1, ob2: PPyObject, i: int): int{.cdecl, importc, dynlib: dllname.} #-
proc PyFile_WriteString*(s: cstring, ob: PPyObject){.cdecl, importc, dynlib: dllname.} #+
proc PyFloat_AsDouble*(ob: PPyObject): float64{.cdecl, importc, dynlib: dllname.} #+
proc PyFloat_FromDouble*(db: float64): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyFunction_GetCode*(ob: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyFunction_GetGlobals*(ob: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyFunction_New*(ob1, ob2: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyImport_AddModule*(name: cstring): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyImport_Cleanup*(){.cdecl, importc, dynlib: dllname.} #-
proc PyImport_GetMagicNumber*(): int32{.cdecl, importc, dynlib: dllname.} #+
proc PyImport_ImportFrozenModule*(key: cstring): int{.cdecl, importc, dynlib: dllname.} #+
proc PyImport_ImportModule*(name: cstring): PPyObject{.cdecl, importc, dynlib: dllname.} #+
proc PyImport_Import*(name: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-

proc PyImport_Init*() {.cdecl, importc, dynlib: dllname.}
proc PyImport_ReloadModule*(ob: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyInstance_New*(obClass, obArg, obKW: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #+
proc PyInt_AsLong*(ob: PPyObject): int32{.cdecl, importc, dynlib: dllname.} #-
proc PyList_Append*(ob1, ob2: PPyObject): int{.cdecl, importc, dynlib: dllname.} #-
proc PyList_AsTuple*(ob: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #+
proc PyList_GetItem*(ob: PPyObject, i: int): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyList_GetSlice*(ob: PPyObject, i1, i2: int): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyList_Insert*(dp: PPyObject, idx: int, item: PPyObject): int{.cdecl, importc, dynlib: dllname.} #-
proc PyList_New*(size: int): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyList_Reverse*(ob: PPyObject): int{.cdecl, importc, dynlib: dllname.} #-
proc PyList_SetItem*(dp: PPyObject, idx: int, item: PPyObject): int{.cdecl, importc, dynlib: dllname.} #-
proc PyList_SetSlice*(ob: PPyObject, i1, i2: int, ob2: PPyObject): int{.
      cdecl, importc, dynlib: dllname.}                 #+
proc PyList_Size*(ob: PPyObject): int{.cdecl, importc, dynlib: dllname.} #-
proc PyList_Sort*(ob: PPyObject): int{.cdecl, importc, dynlib: dllname.} #-
proc PyLong_AsDouble*(ob: PPyObject): float64{.cdecl, importc, dynlib: dllname.} #+
proc PyLong_AsLong*(ob: PPyObject): int32{.cdecl, importc, dynlib: dllname.} #+
proc PyLong_FromDouble*(db: float64): PPyObject{.cdecl, importc, dynlib: dllname.} #+
proc PyLong_FromLong*(L: int32): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyLong_FromString*(pc: cstring, ppc: var cstring, i: int): PPyObject{.
      cdecl, importc, dynlib: dllname.}                 #-
proc PyLong_FromUnsignedLong*(val: int): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyLong_AsUnsignedLong*(ob: PPyObject): int{.cdecl, importc, dynlib: dllname.} #-
proc PyLong_FromUnicode*(ob: PPyObject, a, b: int): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyLong_FromLongLong*(val: Int64): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyLong_AsLongLong*(ob: PPyObject): Int64{.cdecl, importc, dynlib: dllname.} #-
proc PyMapping_Check*(ob: PPyObject): int{.cdecl, importc, dynlib: dllname.} #-
proc PyMapping_GetItemString*(ob: PPyObject, key: cstring): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyMapping_HasKey*(ob, key: PPyObject): int{.cdecl, importc, dynlib: dllname.} #-
proc PyMapping_HasKeyString*(ob: PPyObject, key: cstring): int{.cdecl, importc, dynlib: dllname.} #-
proc PyMapping_Length*(ob: PPyObject): int{.cdecl, importc, dynlib: dllname.} #-
proc PyMapping_SetItemString*(ob: PPyObject, key: cstring, value: PPyObject): int{.
      cdecl, importc, dynlib: dllname.}                 #-
proc PyMethod_Class*(ob: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyMethod_Function*(ob: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyMethod_New*(ob1, ob2, ob3: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyMethod_Self*(ob: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyModule_GetName*(ob: PPyObject): cstring{.cdecl, importc, dynlib: dllname.} #-
proc PyModule_New*(key: cstring): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Absolute*(ob: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Add*(ob1, ob2: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_And*(ob1, ob2: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Check*(ob: PPyObject): int{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Coerce*(ob1, ob2: var PPyObject): int{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Divide*(ob1, ob2: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_FloorDivide*(ob1, ob2: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_TrueDivide*(ob1, ob2: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Divmod*(ob1, ob2: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Float*(ob: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Int*(ob: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Invert*(ob: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Long*(ob: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Lshift*(ob1, ob2: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Multiply*(ob1, ob2: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Negative*(ob: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Or*(ob1, ob2: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Positive*(ob: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Power*(ob1, ob2, ob3: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Remainder*(ob1, ob2: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Rshift*(ob1, ob2: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Subtract*(ob1, ob2: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Xor*(ob1, ob2: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyOS_InitInterrupts*(){.cdecl, importc, dynlib: dllname.} #-
proc PyOS_InterruptOccurred*(): int{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_CallObject*(ob, args: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_Compare*(ob1, ob2: PPyObject): int{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_GetAttr*(ob1, ob2: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #+
proc PyObject_GetAttrString*(ob: PPyObject, c: cstring): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_GetItem*(ob, key: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_DelItem*(ob, key: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_HasAttrString*(ob: PPyObject, key: cstring): int{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_Hash*(ob: PPyObject): int32{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_IsTrue*(ob: PPyObject): int{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_Length*(ob: PPyObject): int{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_Repr*(ob: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_SetAttr*(ob1, ob2, ob3: PPyObject): int{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_SetAttrString*(ob: PPyObject, key: cstring, value: PPyObject): int{.
      cdecl, importc, dynlib: dllname.}                 #-
proc PyObject_SetItem*(ob1, ob2, ob3: PPyObject): int{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_Init*(ob: PPyObject, t: PPyTypeObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_InitVar*(ob: PPyObject, t: PPyTypeObject, size: int): PPyObject{.
      cdecl, importc, dynlib: dllname.}                 #-
proc PyObject_New*(t: PPyTypeObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_NewVar*(t: PPyTypeObject, size: int): PPyObject{.cdecl, importc, dynlib: dllname.}
proc PyObject_Free*(ob: PPyObject){.cdecl, importc, dynlib: dllname.} #-
proc PyObject_IsInstance*(inst, cls: PPyObject): int{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_IsSubclass*(derived, cls: PPyObject): int{.cdecl, importc, dynlib: dllname.}
proc PyObject_GenericGetAttr*(obj, name: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.}
proc PyObject_GenericSetAttr*(obj, name, value: PPyObject): int{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_GC_Malloc*(size: int): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_GC_New*(t: PPyTypeObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_GC_NewVar*(t: PPyTypeObject, size: int): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_GC_Resize*(t: PPyObject, newsize: int): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_GC_Del*(ob: PPyObject){.cdecl, importc, dynlib: dllname.} #-
proc PyObject_GC_Track*(ob: PPyObject){.cdecl, importc, dynlib: dllname.} #-
proc PyObject_GC_UnTrack*(ob: PPyObject){.cdecl, importc, dynlib: dllname.} #-
proc PyRange_New*(l1, l2, l3: int32, i: int): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PySequence_Check*(ob: PPyObject): int{.cdecl, importc, dynlib: dllname.} #-
proc PySequence_Concat*(ob1, ob2: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PySequence_Count*(ob1, ob2: PPyObject): int{.cdecl, importc, dynlib: dllname.} #-
proc PySequence_GetItem*(ob: PPyObject, i: int): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PySequence_GetSlice*(ob: PPyObject, i1, i2: int): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PySequence_In*(ob1, ob2: PPyObject): int{.cdecl, importc, dynlib: dllname.} #-
proc PySequence_Index*(ob1, ob2: PPyObject): int{.cdecl, importc, dynlib: dllname.} #-
proc PySequence_Length*(ob: PPyObject): int{.cdecl, importc, dynlib: dllname.} #-
proc PySequence_Repeat*(ob: PPyObject, count: int): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PySequence_SetItem*(ob: PPyObject, i: int, value: PPyObject): int{.
      cdecl, importc, dynlib: dllname.}                 #-
proc PySequence_SetSlice*(ob: PPyObject, i1, i2: int, value: PPyObject): int{.
      cdecl, importc, dynlib: dllname.}                 #-
proc PySequence_DelSlice*(ob: PPyObject, i1, i2: int): int{.cdecl, importc, dynlib: dllname.} #-
proc PySequence_Tuple*(ob: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PySequence_Contains*(ob, value: PPyObject): int{.cdecl, importc, dynlib: dllname.} #-
proc PySlice_GetIndices*(ob: PPySliceObject, len: int,
                             start, stop, step: var int): int{.cdecl, importc, dynlib: dllname.} #-
proc PySlice_GetIndicesEx*(ob: PPySliceObject, len: int,
                               start, stop, step, slicelength: var int): int{.
      cdecl, importc, dynlib: dllname.}                 #-
proc PySlice_New*(start, stop, step: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyString_Concat*(ob1: var PPyObject, ob2: PPyObject){.cdecl, importc, dynlib: dllname.} #-
proc PyString_ConcatAndDel*(ob1: var PPyObject, ob2: PPyObject){.cdecl, importc, dynlib: dllname.} #-
proc PyString_Format*(ob1, ob2: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyString_FromStringAndSize*(s: cstring, i: int): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyString_Size*(ob: PPyObject): int{.cdecl, importc, dynlib: dllname.} #-
proc PyString_DecodeEscape*(s: cstring, length: int, errors: cstring,
                                unicode: int, recode_encoding: cstring): PPyObject{.
      cdecl, importc, dynlib: dllname.}                 #-
proc PyString_Repr*(ob: PPyObject, smartquotes: int): PPyObject{.cdecl, importc, dynlib: dllname.} #+
proc PySys_GetObject*(s: cstring): PPyObject{.cdecl, importc, dynlib: dllname.}
#-
#PySys_Init:procedure; cdecl, importc, dynlib: dllname;
#-
proc PySys_SetObject*(s: cstring, ob: PPyObject): int{.cdecl, importc, dynlib: dllname.} #-
proc PySys_SetPath*(path: cstring){.cdecl, importc, dynlib: dllname.} #-
#PyTraceBack_Fetch:function:PPyObject; cdecl, importc, dynlib: dllname;
#-
proc PyTraceBack_Here*(p: pointer): int{.cdecl, importc, dynlib: dllname.} #-
proc PyTraceBack_Print*(ob1, ob2: PPyObject): int{.cdecl, importc, dynlib: dllname.} #-
#PyTraceBack_Store:function (ob:PPyObject):integer; cdecl, importc, dynlib: dllname;
#+
proc PyTuple_GetItem*(ob: PPyObject, i: int): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc PyTuple_GetSlice*(ob: PPyObject, i1, i2: int): PPyObject{.cdecl, importc, dynlib: dllname.} #+
proc PyTuple_New*(size: int): PPyObject{.cdecl, importc, dynlib: dllname.} #+
proc PyTuple_SetItem*(ob: PPyObject, key: int, value: PPyObject): int{.cdecl, importc, dynlib: dllname.} #+
proc PyTuple_Size*(ob: PPyObject): int{.cdecl, importc, dynlib: dllname.} #+
proc PyType_IsSubtype*(a, b: PPyTypeObject): int{.cdecl, importc, dynlib: dllname.}
proc PyType_GenericAlloc*(atype: PPyTypeObject, nitems: int): PPyObject{.
      cdecl, importc, dynlib: dllname.}
proc PyType_GenericNew*(atype: PPyTypeObject, args, kwds: PPyObject): PPyObject{.
      cdecl, importc, dynlib: dllname.}
proc PyType_Ready*(atype: PPyTypeObject): int{.cdecl, importc, dynlib: dllname.} #+
proc PyUnicode_FromWideChar*(w: pointer, size: int): PPyObject{.cdecl, importc, dynlib: dllname.} #+
proc PyUnicode_AsWideChar*(unicode: PPyObject, w: pointer, size: int): int{.
      cdecl, importc, dynlib: dllname.}                 #-
proc PyUnicode_FromOrdinal*(ordinal: int): PPyObject{.cdecl, importc, dynlib: dllname.}
proc PyWeakref_GetObject*(theRef: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.}
proc PyWeakref_NewProxy*(ob, callback: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.}
proc PyWeakref_NewRef*(ob, callback: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.}
proc PyWrapper_New*(ob1, ob2: PPyObject): PPyObject{.cdecl, importc, dynlib: dllname.}
proc PyBool_FromLong*(ok: int): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc Py_AtExit*(prc: proc () {.cdecl.}): int{.cdecl, importc, dynlib: dllname.} #-
#Py_Cleanup:procedure; cdecl, importc, dynlib: dllname;
#-
proc Py_CompileString*(s1, s2: cstring, i: int): PPyObject{.cdecl, importc, dynlib: dllname.} #-
proc Py_FatalError*(s: cstring){.cdecl, importc, dynlib: dllname.} #-
proc Py_FindMethod*(md: PPyMethodDef, ob: PPyObject, key: cstring): PPyObject{.
      cdecl, importc, dynlib: dllname.}                 #-
proc Py_FindMethodInChain*(mc: PPyMethodChain, ob: PPyObject, key: cstring): PPyObject{.
      cdecl, importc, dynlib: dllname.}                 #-
proc Py_FlushLine*(){.cdecl, importc, dynlib: dllname.} #+
proc Py_Finalize*(){.cdecl, importc, dynlib: dllname.} #-
proc PyErr_ExceptionMatches*(exc: PPyObject): int{.cdecl, importc, dynlib: dllname.} #-
proc PyErr_GivenExceptionMatches*(raised_exc, exc: PPyObject): int{.cdecl, importc, dynlib: dllname.} #-
proc PyEval_EvalCode*(co: PPyCodeObject, globals, locals: PPyObject): PPyObject{.
      cdecl, importc, dynlib: dllname.}                 #+
proc Py_GetVersion*(): cstring{.cdecl, importc, dynlib: dllname.} #+
proc Py_GetCopyright*(): cstring{.cdecl, importc, dynlib: dllname.} #+
proc Py_GetExecPrefix*(): cstring{.cdecl, importc, dynlib: dllname.} #+
proc Py_GetPath*(): cstring{.cdecl, importc, dynlib: dllname.} #+
proc Py_GetPrefix*(): cstring{.cdecl, importc, dynlib: dllname.} #+
proc Py_GetProgramName*(): cstring{.cdecl, importc, dynlib: dllname.} #-
proc PyParser_SimpleParseString*(str: cstring, start: int): PNode{.cdecl, importc, dynlib: dllname.} #-
proc PyNode_Free*(n: PNode){.cdecl, importc, dynlib: dllname.} #-
proc PyErr_NewException*(name: cstring, base, dict: PPyObject): PPyObject{.
      cdecl, importc, dynlib: dllname.}                 #-
proc Py_Malloc*(size: int): Pointer {.cdecl, importc, dynlib: dllname.}
proc PyMem_Malloc*(size: int): Pointer {.cdecl, importc, dynlib: dllname.}
proc PyObject_CallMethod*(obj: PPyObject, theMethod,
                              format: cstring): PPyObject{.cdecl, importc, dynlib: dllname.}
proc Py_SetProgramName*(name: cstring){.cdecl, importc, dynlib: dllname.}
proc Py_IsInitialized*(): int{.cdecl, importc, dynlib: dllname.}
proc Py_GetProgramFullPath*(): cstring{.cdecl, importc, dynlib: dllname.}
proc Py_NewInterpreter*(): PPyThreadState{.cdecl, importc, dynlib: dllname.}
proc Py_EndInterpreter*(tstate: PPyThreadState){.cdecl, importc, dynlib: dllname.}
proc PyEval_AcquireLock*(){.cdecl, importc, dynlib: dllname.}
proc PyEval_ReleaseLock*(){.cdecl, importc, dynlib: dllname.}
proc PyEval_AcquireThread*(tstate: PPyThreadState){.cdecl, importc, dynlib: dllname.}
proc PyEval_ReleaseThread*(tstate: PPyThreadState){.cdecl, importc, dynlib: dllname.}
proc PyInterpreterState_New*(): PPyInterpreterState{.cdecl, importc, dynlib: dllname.}
proc PyInterpreterState_Clear*(interp: PPyInterpreterState){.cdecl, importc, dynlib: dllname.}
proc PyInterpreterState_Delete*(interp: PPyInterpreterState){.cdecl, importc, dynlib: dllname.}
proc PyThreadState_New*(interp: PPyInterpreterState): PPyThreadState{.cdecl, importc, dynlib: dllname.}
proc PyThreadState_Clear*(tstate: PPyThreadState){.cdecl, importc, dynlib: dllname.}
proc PyThreadState_Delete*(tstate: PPyThreadState){.cdecl, importc, dynlib: dllname.}
proc PyThreadState_Get*(): PPyThreadState{.cdecl, importc, dynlib: dllname.}
proc PyThreadState_Swap*(tstate: PPyThreadState): PPyThreadState{.cdecl, importc, dynlib: dllname.}

#Further exported Objects, may be implemented later
#
#    PyCode_New: Pointer;
#    PyErr_SetInterrupt: Pointer;
#    PyFile_AsFile: Pointer;
#    PyFile_FromFile: Pointer;
#    PyFloat_AsString: Pointer;
#    PyFrame_BlockPop: Pointer;
#    PyFrame_BlockSetup: Pointer;
#    PyFrame_ExtendStack: Pointer;
#    PyFrame_FastToLocals: Pointer;
#    PyFrame_LocalsToFast: Pointer;
#    PyFrame_New: Pointer;
#    PyGrammar_AddAccelerators: Pointer;
#    PyGrammar_FindDFA: Pointer;
#    PyGrammar_LabelRepr: Pointer;
#    PyInstance_DoBinOp: Pointer;
#    PyInt_GetMax: Pointer;
#    PyMarshal_Init: Pointer;
#    PyMarshal_ReadLongFromFile: Pointer;
#    PyMarshal_ReadObjectFromFile: Pointer;
#    PyMarshal_ReadObjectFromString: Pointer;
#    PyMarshal_WriteLongToFile: Pointer;
#    PyMarshal_WriteObjectToFile: Pointer;
#    PyMember_Get: Pointer;
#    PyMember_Set: Pointer;
#    PyNode_AddChild: Pointer;
#    PyNode_Compile: Pointer;
#    PyNode_New: Pointer;
#    PyOS_GetLastModificationTime: Pointer;
#    PyOS_Readline: Pointer;
#    PyOS_strtol: Pointer;
#    PyOS_strtoul: Pointer;
#    PyObject_CallFunction: Pointer;
#    PyObject_CallMethod: Pointer;
#    PyObject_Print: Pointer;
#    PyParser_AddToken: Pointer;
#    PyParser_Delete: Pointer;
#    PyParser_New: Pointer;
#    PyParser_ParseFile: Pointer;
#    PyParser_ParseString: Pointer;
#    PyParser_SimpleParseFile: Pointer;
#    PyRun_AnyFile: Pointer;
#    PyRun_File: Pointer;
#    PyRun_InteractiveLoop: Pointer;
#    PyRun_InteractiveOne: Pointer;
#    PyRun_SimpleFile: Pointer;
#    PySys_GetFile: Pointer;
#    PyToken_OneChar: Pointer;
#    PyToken_TwoChars: Pointer;
#    PyTokenizer_Free: Pointer;
#    PyTokenizer_FromFile: Pointer;
#    PyTokenizer_FromString: Pointer;
#    PyTokenizer_Get: Pointer;
#    Py_Main: Pointer;
#    _PyObject_NewVar: Pointer;
#    _PyParser_Grammar: Pointer;
#    _PyParser_TokenNames: Pointer;
#    _PyThread_Started: Pointer;
#    _Py_c_diff: Pointer;
#    _Py_c_neg: Pointer;
#    _Py_c_pow: Pointer;
#    _Py_c_prod: Pointer;
#    _Py_c_quot: Pointer;
#    _Py_c_sum: Pointer;
#

# This function handles all cardinals, pointer types (with no adjustment of pointers!)
# (Extended) floats, which are handled as Python doubles and currencies, handled
# as (normalized) Python doubles.
proc PyImport_ExecCodeModule*(name: String, codeobject: PPyObject): PPyObject
proc PyString_Check*(obj: PPyObject): bool
proc PyString_CheckExact*(obj: PPyObject): bool
proc PyFloat_Check*(obj: PPyObject): bool
proc PyFloat_CheckExact*(obj: PPyObject): bool
proc PyInt_Check*(obj: PPyObject): bool
proc PyInt_CheckExact*(obj: PPyObject): bool
proc PyLong_Check*(obj: PPyObject): bool
proc PyLong_CheckExact*(obj: PPyObject): bool
proc PyTuple_Check*(obj: PPyObject): bool
proc PyTuple_CheckExact*(obj: PPyObject): bool
proc PyInstance_Check*(obj: PPyObject): bool
proc PyClass_Check*(obj: PPyObject): bool
proc PyMethod_Check*(obj: PPyObject): bool
proc PyList_Check*(obj: PPyObject): bool
proc PyList_CheckExact*(obj: PPyObject): bool
proc PyDict_Check*(obj: PPyObject): bool
proc PyDict_CheckExact*(obj: PPyObject): bool
proc PyModule_Check*(obj: PPyObject): bool
proc PyModule_CheckExact*(obj: PPyObject): bool
proc PySlice_Check*(obj: PPyObject): bool
proc PyFunction_Check*(obj: PPyObject): bool
proc PyUnicode_Check*(obj: PPyObject): bool
proc PyUnicode_CheckExact*(obj: PPyObject): bool
proc PyType_IS_GC*(t: PPyTypeObject): bool
proc PyObject_IS_GC*(obj: PPyObject): bool
proc PyBool_Check*(obj: PPyObject): bool
proc PyBaseString_Check*(obj: PPyObject): bool
proc PyEnum_Check*(obj: PPyObject): bool
proc PyObject_TypeCheck*(obj: PPyObject, t: PPyTypeObject): bool
proc Py_InitModule*(name: cstring, md: PPyMethodDef): PPyObject
proc PyType_HasFeature*(AType: PPyTypeObject, AFlag: int): bool
# implementation

proc Py_INCREF*(op: PPyObject) {.inline.} =
  Inc(op.ob_refcnt)

proc Py_DECREF*(op: PPyObject) {.inline.} =
  Dec(op.ob_refcnt)
  if op.ob_refcnt == 0:
    op.ob_type.tp_dealloc(op)

proc Py_XINCREF*(op: PPyObject) {.inline.} =
  if op != nil: Py_INCREF(op)

proc Py_XDECREF*(op: PPyObject) {.inline.} =
  if op != nil: Py_DECREF(op)

proc PyImport_ExecCodeModule(name: string, codeobject: PPyObject): PPyObject =
  var m, d, v, modules: PPyObject
  m = PyImport_AddModule(cstring(name))
  if m == nil:
    return nil
  d = PyModule_GetDict(m)
  if PyDict_GetItemString(d, "__builtins__") == nil:
    if PyDict_SetItemString(d, "__builtins__", PyEval_GetBuiltins()) != 0:
      return nil
  if PyDict_SetItemString(d, "__file__",
                          PPyCodeObject(codeobject).co_filename) != 0:
    PyErr_Clear() # Not important enough to report
  v = PyEval_EvalCode(PPyCodeObject(codeobject), d, d) # XXX owner ?
  if v == nil:
    return nil
  Py_XDECREF(v)
  modules = PyImport_GetModuleDict()
  if PyDict_GetItemString(modules, cstring(name)) == nil:
    PyErr_SetString(PyExc_ImportError[] , cstring(
        "Loaded module " & name & "not found in sys.modules"))
    return nil
  Py_XINCREF(m)
  Result = m

proc PyString_Check(obj: PPyObject): bool =
  Result = PyObject_TypeCheck(obj, PyString_Type)

proc PyString_CheckExact(obj: PPyObject): bool =
  Result = (obj != nil) and (obj.ob_type == PyString_Type)

proc PyFloat_Check(obj: PPyObject): bool =
  Result = PyObject_TypeCheck(obj, PyFloat_Type)

proc PyFloat_CheckExact(obj: PPyObject): bool =
  Result = (obj != nil) and (obj.ob_type == PyFloat_Type)

proc PyInt_Check(obj: PPyObject): bool =
  Result = PyObject_TypeCheck(obj, PyInt_Type)

proc PyInt_CheckExact(obj: PPyObject): bool =
  Result = (obj != nil) and (obj.ob_type == PyInt_Type)

proc PyLong_Check(obj: PPyObject): bool =
  Result = PyObject_TypeCheck(obj, PyLong_Type)

proc PyLong_CheckExact(obj: PPyObject): bool =
  Result = (obj != nil) and (obj.ob_type == PyLong_Type)

proc PyTuple_Check(obj: PPyObject): bool =
  Result = PyObject_TypeCheck(obj, PyTuple_Type)

proc PyTuple_CheckExact(obj: PPyObject): bool =
  Result = (obj != nil) and (obj[].ob_type == PyTuple_Type)

proc PyInstance_Check(obj: PPyObject): bool =
  Result = (obj != nil) and (obj[].ob_type == PyInstance_Type)

proc PyClass_Check(obj: PPyObject): bool =
  Result = (obj != nil) and (obj[].ob_type == PyClass_Type)

proc PyMethod_Check(obj: PPyObject): bool =
  Result = (obj != nil) and (obj[].ob_type == PyMethod_Type)

proc PyList_Check(obj: PPyObject): bool =
  Result = PyObject_TypeCheck(obj, PyList_Type)

proc PyList_CheckExact(obj: PPyObject): bool =
  Result = (obj != nil) and (obj[].ob_type == PyList_Type)

proc PyDict_Check(obj: PPyObject): bool =
  Result = PyObject_TypeCheck(obj, PyDict_Type)

proc PyDict_CheckExact(obj: PPyObject): bool =
  Result = (obj != nil) and (obj[].ob_type == PyDict_Type)

proc PyModule_Check(obj: PPyObject): bool =
  Result = PyObject_TypeCheck(obj, PyModule_Type)

proc PyModule_CheckExact(obj: PPyObject): bool =
  Result = (obj != nil) and (obj[].ob_type == PyModule_Type)

proc PySlice_Check(obj: PPyObject): bool =
  Result = (obj != nil) and (obj[].ob_type == PySlice_Type)

proc PyFunction_Check(obj: PPyObject): bool =
  Result = (obj != nil) and
      ((obj.ob_type == PyCFunction_Type) or
      (obj.ob_type == PyFunction_Type))

proc PyUnicode_Check(obj: PPyObject): bool =
  Result = PyObject_TypeCheck(obj, PyUnicode_Type)

proc PyUnicode_CheckExact(obj: PPyObject): bool =
  Result = (obj != nil) and (obj.ob_type == PyUnicode_Type)

proc PyType_IS_GC(t: PPyTypeObject): bool =
  Result = PyType_HasFeature(t, Py_TPFLAGS_HAVE_GC)

proc PyObject_IS_GC(obj: PPyObject): bool =
  Result = PyType_IS_GC(obj.ob_type) and
      ((obj.ob_type.tp_is_gc == nil) or (obj.ob_type.tp_is_gc(obj) == 1))

proc PyBool_Check(obj: PPyObject): bool =
  Result = (obj != nil) and (obj.ob_type == PyBool_Type)

proc PyBaseString_Check(obj: PPyObject): bool =
  Result = PyObject_TypeCheck(obj, PyBaseString_Type)

proc PyEnum_Check(obj: PPyObject): bool =
  Result = (obj != nil) and (obj.ob_type == PyEnum_Type)

proc PyObject_TypeCheck(obj: PPyObject, t: PPyTypeObject): bool =
  Result = (obj != nil) and (obj.ob_type == t)
  if not Result and (obj != nil) and (t != nil):
    Result = PyType_IsSubtype(obj.ob_type, t) == 1

proc Py_InitModule(name: cstring, md: PPyMethodDef): PPyObject =
  result = Py_InitModule4(name, md, nil, nil, 1012)

proc PyType_HasFeature(AType: PPyTypeObject, AFlag: int): bool =
  #(((t)->tp_flags & (f)) != 0)
  Result = (AType.tp_flags and AFlag) != 0

proc init(lib: TLibHandle) =
  Py_DebugFlag = cast[PInt](symAddr(lib, "Py_DebugFlag"))
  Py_VerboseFlag = cast[PInt](symAddr(lib, "Py_VerboseFlag"))
  Py_InteractiveFlag = cast[PInt](symAddr(lib, "Py_InteractiveFlag"))
  Py_OptimizeFlag = cast[PInt](symAddr(lib, "Py_OptimizeFlag"))
  Py_NoSiteFlag = cast[PInt](symAddr(lib, "Py_NoSiteFlag"))
  Py_UseClassExceptionsFlag = cast[PInt](symAddr(lib, "Py_UseClassExceptionsFlag"))
  Py_FrozenFlag = cast[PInt](symAddr(lib, "Py_FrozenFlag"))
  Py_TabcheckFlag = cast[PInt](symAddr(lib, "Py_TabcheckFlag"))
  Py_UnicodeFlag = cast[PInt](symAddr(lib, "Py_UnicodeFlag"))
  Py_IgnoreEnvironmentFlag = cast[PInt](symAddr(lib, "Py_IgnoreEnvironmentFlag"))
  Py_DivisionWarningFlag = cast[PInt](symAddr(lib, "Py_DivisionWarningFlag"))
  Py_None = cast[PPyObject](symAddr(lib, "_Py_NoneStruct"))
  Py_Ellipsis = cast[PPyObject](symAddr(lib, "_Py_EllipsisObject"))
  Py_False = cast[PPyIntObject](symAddr(lib, "_Py_ZeroStruct"))
  Py_True = cast[PPyIntObject](symAddr(lib, "_Py_TrueStruct"))
  Py_NotImplemented = cast[PPyObject](symAddr(lib, "_Py_NotImplementedStruct"))
  PyImport_FrozenModules = cast[PP_frozen](symAddr(lib, "PyImport_FrozenModules"))
  PyExc_AttributeError = cast[PPPyObject](symAddr(lib, "PyExc_AttributeError"))
  PyExc_EOFError = cast[PPPyObject](symAddr(lib, "PyExc_EOFError"))
  PyExc_IOError = cast[PPPyObject](symAddr(lib, "PyExc_IOError"))
  PyExc_ImportError = cast[PPPyObject](symAddr(lib, "PyExc_ImportError"))
  PyExc_IndexError = cast[PPPyObject](symAddr(lib, "PyExc_IndexError"))
  PyExc_KeyError = cast[PPPyObject](symAddr(lib, "PyExc_KeyError"))
  PyExc_KeyboardInterrupt = cast[PPPyObject](symAddr(lib, "PyExc_KeyboardInterrupt"))
  PyExc_MemoryError = cast[PPPyObject](symAddr(lib, "PyExc_MemoryError"))
  PyExc_NameError = cast[PPPyObject](symAddr(lib, "PyExc_NameError"))
  PyExc_OverflowError = cast[PPPyObject](symAddr(lib, "PyExc_OverflowError"))
  PyExc_RuntimeError = cast[PPPyObject](symAddr(lib, "PyExc_RuntimeError"))
  PyExc_SyntaxError = cast[PPPyObject](symAddr(lib, "PyExc_SyntaxError"))
  PyExc_SystemError = cast[PPPyObject](symAddr(lib, "PyExc_SystemError"))
  PyExc_SystemExit = cast[PPPyObject](symAddr(lib, "PyExc_SystemExit"))
  PyExc_TypeError = cast[PPPyObject](symAddr(lib, "PyExc_TypeError"))
  PyExc_ValueError = cast[PPPyObject](symAddr(lib, "PyExc_ValueError"))
  PyExc_ZeroDivisionError = cast[PPPyObject](symAddr(lib, "PyExc_ZeroDivisionError"))
  PyExc_ArithmeticError = cast[PPPyObject](symAddr(lib, "PyExc_ArithmeticError"))
  PyExc_Exception = cast[PPPyObject](symAddr(lib, "PyExc_Exception"))
  PyExc_FloatingPointError = cast[PPPyObject](symAddr(lib, "PyExc_FloatingPointError"))
  PyExc_LookupError = cast[PPPyObject](symAddr(lib, "PyExc_LookupError"))
  PyExc_StandardError = cast[PPPyObject](symAddr(lib, "PyExc_StandardError"))
  PyExc_AssertionError = cast[PPPyObject](symAddr(lib, "PyExc_AssertionError"))
  PyExc_EnvironmentError = cast[PPPyObject](symAddr(lib, "PyExc_EnvironmentError"))
  PyExc_IndentationError = cast[PPPyObject](symAddr(lib, "PyExc_IndentationError"))
  PyExc_MemoryErrorInst = cast[PPPyObject](symAddr(lib, "PyExc_MemoryErrorInst"))
  PyExc_NotImplementedError = cast[PPPyObject](symAddr(lib, "PyExc_NotImplementedError"))
  PyExc_OSError = cast[PPPyObject](symAddr(lib, "PyExc_OSError"))
  PyExc_TabError = cast[PPPyObject](symAddr(lib, "PyExc_TabError"))
  PyExc_UnboundLocalError = cast[PPPyObject](symAddr(lib, "PyExc_UnboundLocalError"))
  PyExc_UnicodeError = cast[PPPyObject](symAddr(lib, "PyExc_UnicodeError"))
  PyExc_Warning = cast[PPPyObject](symAddr(lib, "PyExc_Warning"))
  PyExc_DeprecationWarning = cast[PPPyObject](symAddr(lib, "PyExc_DeprecationWarning"))
  PyExc_RuntimeWarning = cast[PPPyObject](symAddr(lib, "PyExc_RuntimeWarning"))
  PyExc_SyntaxWarning = cast[PPPyObject](symAddr(lib, "PyExc_SyntaxWarning"))
  PyExc_UserWarning = cast[PPPyObject](symAddr(lib, "PyExc_UserWarning"))
  PyExc_OverflowWarning = cast[PPPyObject](symAddr(lib, "PyExc_OverflowWarning"))
  PyExc_ReferenceError = cast[PPPyObject](symAddr(lib, "PyExc_ReferenceError"))
  PyExc_StopIteration = cast[PPPyObject](symAddr(lib, "PyExc_StopIteration"))
  PyExc_FutureWarning = cast[PPPyObject](symAddr(lib, "PyExc_FutureWarning"))
  PyExc_PendingDeprecationWarning = cast[PPPyObject](symAddr(lib,
      "PyExc_PendingDeprecationWarning"))
  PyExc_UnicodeDecodeError = cast[PPPyObject](symAddr(lib, "PyExc_UnicodeDecodeError"))
  PyExc_UnicodeEncodeError = cast[PPPyObject](symAddr(lib, "PyExc_UnicodeEncodeError"))
  PyExc_UnicodeTranslateError = cast[PPPyObject](symAddr(lib, "PyExc_UnicodeTranslateError"))
  PyType_Type = cast[PPyTypeObject](symAddr(lib, "PyType_Type"))
  PyCFunction_Type = cast[PPyTypeObject](symAddr(lib, "PyCFunction_Type"))
  PyCObject_Type = cast[PPyTypeObject](symAddr(lib, "PyCObject_Type"))
  PyClass_Type = cast[PPyTypeObject](symAddr(lib, "PyClass_Type"))
  PyCode_Type = cast[PPyTypeObject](symAddr(lib, "PyCode_Type"))
  PyComplex_Type = cast[PPyTypeObject](symAddr(lib, "PyComplex_Type"))
  PyDict_Type = cast[PPyTypeObject](symAddr(lib, "PyDict_Type"))
  PyFile_Type = cast[PPyTypeObject](symAddr(lib, "PyFile_Type"))
  PyFloat_Type = cast[PPyTypeObject](symAddr(lib, "PyFloat_Type"))
  PyFrame_Type = cast[PPyTypeObject](symAddr(lib, "PyFrame_Type"))
  PyFunction_Type = cast[PPyTypeObject](symAddr(lib, "PyFunction_Type"))
  PyInstance_Type = cast[PPyTypeObject](symAddr(lib, "PyInstance_Type"))
  PyInt_Type = cast[PPyTypeObject](symAddr(lib, "PyInt_Type"))
  PyList_Type = cast[PPyTypeObject](symAddr(lib, "PyList_Type"))
  PyLong_Type = cast[PPyTypeObject](symAddr(lib, "PyLong_Type"))
  PyMethod_Type = cast[PPyTypeObject](symAddr(lib, "PyMethod_Type"))
  PyModule_Type = cast[PPyTypeObject](symAddr(lib, "PyModule_Type"))
  PyObject_Type = cast[PPyTypeObject](symAddr(lib, "PyObject_Type"))
  PyRange_Type = cast[PPyTypeObject](symAddr(lib, "PyRange_Type"))
  PySlice_Type = cast[PPyTypeObject](symAddr(lib, "PySlice_Type"))
  PyString_Type = cast[PPyTypeObject](symAddr(lib, "PyString_Type"))
  PyTuple_Type = cast[PPyTypeObject](symAddr(lib, "PyTuple_Type"))
  PyUnicode_Type = cast[PPyTypeObject](symAddr(lib, "PyUnicode_Type"))
  PyBaseObject_Type = cast[PPyTypeObject](symAddr(lib, "PyBaseObject_Type"))
  PyBuffer_Type = cast[PPyTypeObject](symAddr(lib, "PyBuffer_Type"))
  PyCallIter_Type = cast[PPyTypeObject](symAddr(lib, "PyCallIter_Type"))
  PyCell_Type = cast[PPyTypeObject](symAddr(lib, "PyCell_Type"))
  PyClassMethod_Type = cast[PPyTypeObject](symAddr(lib, "PyClassMethod_Type"))
  PyProperty_Type = cast[PPyTypeObject](symAddr(lib, "PyProperty_Type"))
  PySeqIter_Type = cast[PPyTypeObject](symAddr(lib, "PySeqIter_Type"))
  PyStaticMethod_Type = cast[PPyTypeObject](symAddr(lib, "PyStaticMethod_Type"))
  PySuper_Type = cast[PPyTypeObject](symAddr(lib, "PySuper_Type"))
  PySymtableEntry_Type = cast[PPyTypeObject](symAddr(lib, "PySymtableEntry_Type"))
  PyTraceBack_Type = cast[PPyTypeObject](symAddr(lib, "PyTraceBack_Type"))
  PyWrapperDescr_Type = cast[PPyTypeObject](symAddr(lib, "PyWrapperDescr_Type"))
  PyBaseString_Type = cast[PPyTypeObject](symAddr(lib, "PyBaseString_Type"))
  PyBool_Type = cast[PPyTypeObject](symAddr(lib, "PyBool_Type"))
  PyEnum_Type = cast[PPyTypeObject](symAddr(lib, "PyEnum_Type"))

# Unfortunately we have to duplicate the loading mechanism here, because Nimrod
# used to not support variables from dynamic libraries. Well designed API's
# don't require this anyway. Python is an exception.

var
  lib: TLibHandle

when defined(windows):
  const
    LibNames = ["python27.dll", "python26.dll", "python25.dll",
      "python24.dll", "python23.dll", "python22.dll", "python21.dll",
      "python20.dll", "python16.dll", "python15.dll"]
elif defined(macosx):
  const
    LibNames = ["libpython2.7.dylib", "libpython2.6.dylib",
      "libpython2.5.dylib", "libpython2.4.dylib", "libpython2.3.dylib",
      "libpython2.2.dylib", "libpython2.1.dylib", "libpython2.0.dylib",
      "libpython1.6.dylib", "libpython1.5.dylib"]
else:
  const
    LibNames = [
      "libpython2.7.so" & dllver,
      "libpython2.6.so" & dllver,
      "libpython2.5.so" & dllver,
      "libpython2.4.so" & dllver,
      "libpython2.3.so" & dllver,
      "libpython2.2.so" & dllver,
      "libpython2.1.so" & dllver,
      "libpython2.0.so" & dllver,
      "libpython1.6.so" & dllver,
      "libpython1.5.so" & dllver]

for libName in items(libNames):
  lib = loadLib(libName)
  if lib != nil: break

if lib == nil: quit("could not load python library")
init(lib)

