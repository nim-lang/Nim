{
    Light-weight binding for the Python interpreter
       (c) 2008 Andreas Rumpf 
    Based on 'PythonEngine' module by Dr. Dietmar Budelsky

}

(**************************************************************************)
(*                                                                        *)
(* Module:  Unit 'PythonEngine'     Copyright (c) 1997                    *)
(*                                                                        *)
(* Version: 3.0                     Dr. Dietmar Budelsky                  *)
(* Sub-Version: 0.25                dbudelsky@web.de                      *)
(*                                  Germany                               *)
(*                                                                        *)
(*                                  Morgan Martinet                       *)
(*                                  4721 rue Brebeuf                      *)
(*                                  H2J 3L2 MONTREAL (QC)                 *)
(*                                  CANADA                                *)
(*                                  e-mail: mmm@free.fr                   *)
(*                                                                        *)
(*  look our page at: http://www.multimania.com/marat                     *)
(**************************************************************************)
(*  Functionality:  Delphi Components that provide an interface to the    *)
(*                  Python language (see python.txt for more infos on     *)
(*                  Python itself).                                       *)
(*                                                                        *)
(**************************************************************************)
(*  Contributors:                                                         *)
(*      Grzegorz Makarewicz (mak@mikroplan.com.pl)                        *)
(*      Andrew Robinson (andy@hps1.demon.co.uk)                           *)
(*      Mark Watts(mark_watts@hotmail.com)                                *)
(*      Olivier Deckmyn (olivier.deckmyn@mail.dotcom.fr)                  *)
(*      Sigve Tjora (public@tjora.no)                                     *)
(*      Mark Derricutt (mark@talios.com)                                  *)
(*      Igor E. Poteryaev (jah@mail.ru)                                   *)
(*      Yuri Filimonov (fil65@mail.ru)                                    *)
(*      Stefan Hoffmeister (Stefan.Hoffmeister@Econos.de)                 *)
(**************************************************************************)
(* This source code is distributed with no WARRANTY, for no reason or use.*)
(* Everyone is allowed to use and change this code free for his own tasks *)
(* and projects, as long as this header and its copyright text is intact. *)
(* For changed versions of this code, which are public distributed the    *)
(* following additional conditions have to be fullfilled:                 *)
(* 1) The header has to contain a comment on the change and the author of *)
(*    it.                                                                 *)
(* 2) A copy of the changed source has to be sent to the above E-Mail     *)
(*    address or my then valid address, if this is possible to the        *)
(*    author.                                                             *)
(* The second condition has the target to maintain an up to date central  *)
(* version of the component. If this condition is not acceptable for      *)
(* confidential or legal reasons, everyone is free to derive a component  *)
(* or to generate a diff file to my or other original sources.            *)
(* Dr. Dietmar Budelsky, 1997-11-17                                       *)
(**************************************************************************)
unit python;

interface

uses
  dyncalls;

{$ifdef windows}
const
  DllName = 'python24.dll';
{$else}
const
  DllName = 'libpython2.4.so'; // for UNIX systems
{$endif}

const
  PYT_METHOD_BUFFER_INCREASE = 10;
  PYT_MEMBER_BUFFER_INCREASE = 10;
  PYT_GETSET_BUFFER_INCREASE = 10;

  METH_VARARGS  = $0001;
  METH_KEYWORDS = $0002;

  // Masks for the co_flags field of PyCodeObject
  CO_OPTIMIZED   = $0001;
  CO_NEWLOCALS   = $0002;
  CO_VARARGS     = $0004;
  CO_VARKEYWORDS = $0008;

type
  // Rich comparison opcodes introduced in version 2.1
  TRichComparisonOpcode = (pyLT, pyLE, pyEQ, pyNE, pyGT, pyGE);
const
{Type flags (tp_flags) introduced in version 2.0

These flags are used to extend the type structure in a backwards-compatible
fashion. Extensions can use the flags to indicate (and test) when a given
type structure contains a new feature. The Python core will use these when
introducing new functionality between major revisions (to avoid mid-version
changes in the PYTHON_API_VERSION).

Arbitration of the flag bit positions will need to be coordinated among
all extension writers who publically release their extensions (this will
be fewer than you might expect!)..

Python 1.5.2 introduced the bf_getcharbuffer slot into PyBufferProcs.

Type definitions should use Py_TPFLAGS_DEFAULT for their tp_flags value.

Code can use PyType_HasFeature(type_ob, flag_value) to test whether the
given type object has a specified feature.
}

// PyBufferProcs contains bf_getcharbuffer
  Py_TPFLAGS_HAVE_GETCHARBUFFER = (1 shl 0);

// PySequenceMethods contains sq_contains
  Py_TPFLAGS_HAVE_SEQUENCE_IN = (1 shl 1);

// Objects which participate in garbage collection (see objimp.h)
  Py_TPFLAGS_GC = (1 shl 2);

// PySequenceMethods and PyNumberMethods contain in-place operators
  Py_TPFLAGS_HAVE_INPLACEOPS = (1 shl 3);

// PyNumberMethods do their own coercion */
  Py_TPFLAGS_CHECKTYPES = (1 shl 4);

  Py_TPFLAGS_HAVE_RICHCOMPARE = (1 shl 5);

// Objects which are weakly referencable if their tp_weaklistoffset is >0
// XXX Should this have the same value as Py_TPFLAGS_HAVE_RICHCOMPARE?
// These both indicate a feature that appeared in the same alpha release.

  Py_TPFLAGS_HAVE_WEAKREFS = (1 shl 6);

// tp_iter is defined
  Py_TPFLAGS_HAVE_ITER = (1 shl 7);

// New members introduced by Python 2.2 exist
  Py_TPFLAGS_HAVE_CLASS = (1 shl 8);

// Set if the type object is dynamically allocated
  Py_TPFLAGS_HEAPTYPE = (1 shl 9);

// Set if the type allows subclassing
  Py_TPFLAGS_BASETYPE = (1 shl 10);

// Set if the type is 'ready' -- fully initialized
  Py_TPFLAGS_READY = (1 shl 12);

// Set while the type is being 'readied', to prevent recursive ready calls
  Py_TPFLAGS_READYING = (1 shl 13);

// Objects support garbage collection (see objimp.h)
  Py_TPFLAGS_HAVE_GC = (1 shl 14);

  Py_TPFLAGS_DEFAULT  =      Py_TPFLAGS_HAVE_GETCHARBUFFER
                             or Py_TPFLAGS_HAVE_SEQUENCE_IN
                             or Py_TPFLAGS_HAVE_INPLACEOPS
                             or Py_TPFLAGS_HAVE_RICHCOMPARE
                             or Py_TPFLAGS_HAVE_WEAKREFS
                             or Py_TPFLAGS_HAVE_ITER
                             or Py_TPFLAGS_HAVE_CLASS;

// See function PyType_HasFeature below for testing the flags.

// Delphi equivalent used by TPythonType
type
  TPFlag = (tpfHaveGetCharBuffer, tpfHaveSequenceIn, tpfGC, tpfHaveInplaceOps,
            tpfCheckTypes, tpfHaveRichCompare, tpfHaveWeakRefs,
            tpfHaveIter, tpfHaveClass, tpfHeapType, tpfBaseType, tpfReady, 
            tpfReadying, tpfHaveGC
           );
  TPFlags = set of TPFlag;
const
  TPFLAGS_DEFAULT = [tpfHaveGetCharBuffer, tpfHaveSequenceIn, tpfHaveInplaceOps,
                     tpfHaveRichCompare, tpfHaveWeakRefs, tpfHaveIter, 
                     tpfHaveClass];
//-------  Python opcodes  ----------//
Const
   single_input                 = 256;
   file_input                   = 257;
   eval_input                   = 258;
   funcdef                      = 259;
   parameters                   = 260;
   varargslist                  = 261;
   fpdef                        = 262;
   fplist                       = 263;
   stmt                         = 264;
   simple_stmt                  = 265;
   small_stmt                   = 266;
   expr_stmt                    = 267;
   augassign                    = 268;
   print_stmt                   = 269;
   del_stmt                     = 270;
   pass_stmt                    = 271;
   flow_stmt                    = 272;
   break_stmt                   = 273;
   continue_stmt                = 274;
   return_stmt                  = 275;
   raise_stmt                   = 276;
   import_stmt                  = 277;
   import_as_name               = 278;
   dotted_as_name               = 279;
   dotted_name                  = 280;
   global_stmt                  = 281;
   exec_stmt                    = 282;
   assert_stmt                  = 283;
   compound_stmt                = 284;
   if_stmt                      = 285;
   while_stmt                   = 286;
   for_stmt                     = 287;
   try_stmt                     = 288;
   except_clause                = 289;
   suite                        = 290;
   test                         = 291;
   and_test                     = 291;
   not_test                     = 293;
   comparison                   = 294;
   comp_op                      = 295;
   expr                         = 296;
   xor_expr                     = 297;
   and_expr                     = 298;
   shift_expr                   = 299;
   arith_expr                   = 300;
   term                         = 301;
   factor                       = 302;
   power                        = 303;
   atom                         = 304;
   listmaker                    = 305;
   lambdef                      = 306;
   trailer                      = 307;
   subscriptlist                = 308;
   subscript                    = 309;
   sliceop                      = 310;
   exprlist                     = 311;
   testlist                     = 312;
   dictmaker                    = 313;
   classdef                     = 314;
   arglist                      = 315;
   argument                     = 316;
   list_iter                    = 317;
   list_for                     = 318;
   list_if                      = 319;

const
  T_SHORT                       = 0;
  T_INT                         = 1;
  T_LONG                        = 2;
  T_FLOAT                       = 3;
  T_DOUBLE                      = 4;
  T_STRING                      = 5;
  T_OBJECT                      = 6;
  T_CHAR                        = 7;	// 1-character string
  T_BYTE                        = 8;	// 8-bit signed int
  T_UBYTE                       = 9;
  T_USHORT                      = 10;
  T_UINT                        = 11;
  T_ULONG                       = 12;

// Added by Jack: strings contained in the structure
  T_STRING_INPLACE= 13;

  T_OBJECT_EX                   = 16;{ Like T_OBJECT, but raises AttributeError
                                        when the value is NULL, instead of
                                        converting to None. }

// Flags
  READONLY                      = 1;
  RO                            = READONLY;		// Shorthand 
  READ_RESTRICTED               = 2;
  WRITE_RESTRICTED              = 4;
  RESTRICTED                    = (READ_RESTRICTED or WRITE_RESTRICTED);
type
  TPyMemberType = (mtShort, mtInt, mtLong, mtFloat, mtDouble, mtString, 
                   mtObject, mtChar, mtByte, mtUByte, mtUShort, mtUInt, 
                   mtULong, mtStringInplace, mtObjectEx);
  TPyMemberFlag = (mfDefault, mfReadOnly, mfReadRestricted, mfWriteRestricted, mfRestricted);

//#######################################################
//##                                                   ##
//##    Global declarations, nothing Python specific   ##
//##                                                   ##
//#######################################################

type
  TPChar  = array[0..16000] of PChar;
  PPChar  = ^TPChar;
  PInt	   = ^Integer;
  PDouble = ^Double;
  PFloat  = ^Real;
  PLong   = ^LongInt;
  PShort  = ^ShortInt;
  PString = ^PChar;

//#######################################################
//##                                                   ##
//##            Python specific interface              ##
//##                                                   ##
//#######################################################

type
  PP_frozen	    = ^Pfrozen;
  P_frozen	    = ^Tfrozen;
  PPyObject	    = ^PyObject;
  PPPyObject	    = ^PPyObject;
  PPPPyObject	    = ^PPPyObject;
  PPyIntObject	    = ^PyIntObject;
  PPyTypeObject     = ^PyTypeObject;
  PPySliceObject    = ^PySliceObject;

  TPyCFunction       = function (self, args: PPyObject): PPyObject; cdecl;

  Tunaryfunc         = function (ob1: PPyObject): PPyObject; cdecl;
  Tbinaryfunc        = function (ob1,ob2: PPyObject): PPyObject; cdecl;
  Tternaryfunc       = function (ob1,ob2,ob3: PPyObject): PPyObject; cdecl;
  Tinquiry           = function (ob1: PPyObject): integer; cdecl;
  Tcoercion          = function (ob1,ob2: PPPyObject): integer; cdecl;
  Tintargfunc        = function (ob1: PPyObject; i: integer): PPyObject; cdecl;
  Tintintargfunc     = function (ob1: PPyObject; i1, i2: integer):
                                PPyObject; cdecl;
  Tintobjargproc     = function (ob1: PPyObject; i: integer; ob2: PPyObject):
                                integer; cdecl;
  Tintintobjargproc  = function (ob1: PPyObject; i1, i2: integer;
                                ob2: PPyObject): integer; cdecl;
  Tobjobjargproc     = function (ob1,ob2,ob3: PPyObject): integer; cdecl;

  Tpydestructor      = procedure (ob: PPyObject); cdecl;
  Tprintfunc         = function (ob: PPyObject; var f: file; i: integer): integer; cdecl;
  Tgetattrfunc       = function (ob1: PPyObject; name: PChar): PPyObject; cdecl;
  Tsetattrfunc       = function (ob1: PPyObject; name: PChar; ob2: PPyObject): integer; cdecl;
  Tcmpfunc           = function (ob1, ob2: PPyObject): integer; cdecl;
  Treprfunc          = function (ob: PPyObject): PPyObject; cdecl;
  Thashfunc          = function (ob: PPyObject): LongInt; cdecl;
  Tgetattrofunc      = function (ob1, ob2: PPyObject): PPyObject; cdecl;
  Tsetattrofunc      = function (ob1, ob2, ob3: PPyObject): integer; cdecl;

/// jah 29-sep-2000: updated for python 2.0
///                   added from object.h
  Tgetreadbufferproc = function (ob1: PPyObject; i: integer; ptr: Pointer): integer; cdecl;
  Tgetwritebufferproc= function (ob1: PPyObject; i: integer; ptr: Pointer): integer; cdecl;
  Tgetsegcountproc   = function (ob1: PPyObject; i: integer): integer; cdecl;
  Tgetcharbufferproc = function (ob1: PPyObject; i: integer; const pstr: PChar): integer; cdecl;
  Tobjobjproc        = function (ob1, ob2: PPyObject): integer; cdecl;
  Tvisitproc         = function (ob1: PPyObject; ptr: Pointer): integer; cdecl;
  Ttraverseproc      = function (ob1: PPyObject; proc: visitproc; ptr: Pointer): integer; cdecl;

  Trichcmpfunc       = function (ob1, ob2: PPyObject; i: Integer): PPyObject; cdecl;
  Tgetiterfunc       = function (ob1: PPyObject): PPyObject; cdecl;
  Titernextfunc      = function (ob1: PPyObject): PPyObject; cdecl;
  Tdescrgetfunc      = function (ob1, ob2, ob3: PPyObject): PPyObject; cdecl;
  Tdescrsetfunc      = function (ob1, ob2, ob3: PPyObject): Integer; cdecl;
  Tinitproc          = function (self, args, kwds: PPyObject): Integer; cdecl;
  Tnewfunc           = function (subtype: PPyTypeObject; args, kwds: PPyObject): PPyObject; cdecl;
  Tallocfunc         = function (self: PPyTypeObject; nitems: integer): PPyObject; cdecl;

  TPyNumberMethods = record
     nb_add: Tbinaryfunc;
     nb_substract: Tbinaryfunc;
     nb_multiply: Tbinaryfunc;
     nb_divide: Tbinaryfunc;
     nb_remainder: Tbinaryfunc;
     nb_divmod: Tbinaryfunc;
     nb_power: Tternaryfunc;
     nb_negative: Tunaryfunc;
     nb_positive: Tunaryfunc;
     nb_absolute: Tunaryfunc;
     nb_nonzero: Tinquiry;
     nb_invert: Tunaryfunc;
     nb_lshift: Tbinaryfunc;
     nb_rshift: Tbinaryfunc;
     nb_and: Tbinaryfunc;
     nb_xor: Tbinaryfunc;
     nb_or: Tbinaryfunc;
     nb_coerce: Tcoercion;
     nb_int: Tunaryfunc;
     nb_long: Tunaryfunc;
     nb_float: Tunaryfunc;
     nb_oct: Tunaryfunc;
     nb_hex: Tunaryfunc;
/// jah 29-sep-2000: updated for python 2.0
///                   added from .h
     nb_inplace_add: Tbinaryfunc;
     nb_inplace_subtract: Tbinaryfunc;
     nb_inplace_multiply: Tbinaryfunc;
     nb_inplace_divide: Tbinaryfunc;
     nb_inplace_remainder: Tbinaryfunc;
     nb_inplace_power: Tternaryfunc;
     nb_inplace_lshift: Tbinaryfunc;
     nb_inplace_rshift: Tbinaryfunc;
     nb_inplace_and: Tbinaryfunc;
     nb_inplace_xor: Tbinaryfunc;
     nb_inplace_or: Tbinaryfunc;
     // Added in release 2.2
     // The following require the Py_TPFLAGS_HAVE_CLASS flag
     nb_floor_divide:         Tbinaryfunc;
     nb_true_divide:          Tbinaryfunc;
     nb_inplace_floor_divide: Tbinaryfunc;
     nb_inplace_true_divide:  Tbinaryfunc;
  end;
  PPyNumberMethods = ^TPyNumberMethods;

  TPySequenceMethods = record
     sq_length: Tinquiry;
     sq_concat: Tbinaryfunc;
     sq_repeat: Tintargfunc;
     sq_item: Tintargfunc;
     sq_slice: Tintintargfunc;
     sq_ass_item: Tintobjargproc;
     sq_ass_slice: Tintintobjargproc;
/// jah 29-sep-2000: updated for python 2.0
///                   added from .h
     sq_contains: Tobjobjproc;
     sq_inplace_concat: Tbinaryfunc;
     sq_inplace_repeat: Tintargfunc;
  end;
  PPySequenceMethods = ^TPySequenceMethods;

  TPyMappingMethods = record
     mp_length	: Tinquiry;
     mp_subscript: Tbinaryfunc;
     mp_ass_subscript: Tobjobjargproc;
  end;
  PPyMappingMethods = ^PyMappingMethods;

/// jah 29-sep-2000: updated for python 2.0
///                   added from .h
  TPyBufferProcs = record
     bf_getreadbuffer: Tgetreadbufferproc;
     bf_getwritebuffer: Tgetwritebufferproc;
     bf_getsegcount: Tgetsegcountproc;
     bf_getcharbuffer: Tgetcharbufferproc;
  end;
  PPyBufferProcs = ^TPyBufferProcs;

  TPy_complex =  record
     real: double;
     imag: double;
  end;

  TPyObject = record
    ob_refcnt: Integer;
    ob_type:   PPyTypeObject;
  end;

  TPyIntObject = object(TPyObject)
    ob_ival: LongInt;
  end;

  PByte = ^Byte;
  Tfrozen = packed record
     name: PChar;
     code: PByte;
     size: Integer;
  end;

  TPySliceObject = object(TPyObject)
    start, stop, step:  PPyObject;
  end;

  PPyMethodDef = ^TPyMethodDef;
  TPyMethodDef  = record
     ml_name:  PChar;
     ml_meth:  TPyCFunction;
     ml_flags: Integer;
     ml_doc:   PChar;
  end;

  // structmember.h
  PPyMemberDef = ^TPyMemberDef;
  TPyMemberDef = record
    name: PChar;
    theType: integer;
    offset: integer;
    flags: integer;
    doc: PChar;
  end;

  // descrobject.h

  // Descriptors

  Tgetter = function (obj: PPyObject; context: Pointer): PPyObject; cdecl;
  Tsetter = function (obj, value: PPyObject; context: Pointer): integer; cdecl;

  PPyGetSetDef = ^TPyGetSetDef;
  TPyGetSetDef = record
    name: PChar;
    get: Tgetter;
    set_: Tsetter;
    doc: PChar;
    closure: Pointer;
  end;

  Twrapperfunc = function (self, args: PPyObject; wrapped: Pointer): PPyObject; cdecl;

  pwrapperbase = ^Twrapperbase;
  Twrapperbase = record
    name: PChar;
    wrapper: Twrapperfunc;
    doc: PChar;
  end;

  // Various kinds of descriptor objects

  {#define PyDescr_COMMON \
          PyObject_HEAD \
          PyTypeObject *d_type; \
          PyObject *d_name
  }

  PPyDescrObject = ^TPyDescrObject;
  TPyDescrObject = object(TPyObject)
    d_type: PPyTypeObject;
    d_name: PPyObject;
  end;

  PPyMethodDescrObject = ^TPyMethodDescrObject;
  TPyMethodDescrObject = object(TPyDescrObject)
    d_method: PPyMethodDef;
  end;

  PPyMemberDescrObject = ^TPyMemberDescrObject;
  TPyMemberDescrObject = object(TPyDescrObject)
    d_member: PPyMemberDef;
  end;

  PPyGetSetDescrObject = ^TPyGetSetDescrObject;
  TPyGetSetDescrObject = object(TPyDescrObject)
    d_getset: PPyGetSetDef;
  end;

  PPyWrapperDescrObject = ^TPyWrapperDescrObject;
  TPyWrapperDescrObject = object(TPyDescrObject)
    d_base: pwrapperbase;
    d_wrapped: Pointer; // This can be any function pointer
  end;

  // object.h
  TPyTypeObject = object(TPyObject)
    ob_size:        Integer; // Number of items in variable part
    tp_name:        PChar;   // For printing
    tp_basicsize, tp_itemsize: Integer; // For allocation

    // Methods to implement standard operations

    tp_dealloc:     Tpydestructor;
    tp_print:       Tprintfunc;
    tp_getattr:     Tgetattrfunc;
    tp_setattr:     Tsetattrfunc;
    tp_compare:     Tcmpfunc;
    tp_repr:        Treprfunc;

    // Method suites for standard classes

    tp_as_number:   PPyNumberMethods;
    tp_as_sequence: PPySequenceMethods;
    tp_as_mapping:  PPyMappingMethods;

    // More standard operations (here for binary compatibility)

    tp_hash:        Thashfunc;
    tp_call:        Tternaryfunc;
    tp_str:         Treprfunc;
    tp_getattro:    Tgetattrofunc;
    tp_setattro:    Tsetattrofunc;

/// jah 29-sep-2000: updated for python 2.0

    // Functions to access object as input/output buffer
    tp_as_buffer:   PPyBufferProcs;
    // Flags to define presence of optional/expanded features
    tp_flags:       LongInt;

    tp_doc:         PChar; // Documentation string

    // call function for all accessible objects
    tp_traverse:    Ttraverseproc;

    // delete references to contained objects
    tp_clear:       Tinquiry;
    // rich comparisons
    tp_richcompare: Trichcmpfunc;

    // weak reference enabler
    tp_weaklistoffset: Longint;
    // Iterators
    tp_iter: Tgetiterfunc;
    tp_iternext: Titernextfunc;

    // Attribute descriptor and subclassing stuff
    tp_methods: PPyMethodDef;
    tp_members: PPyMemberDef;
    tp_getset: PPyGetSetDef;
    tp_base: PPyTypeObject;
    tp_dict: PPyObject;
    tp_descr_get: Tdescrgetfunc;
    tp_descr_set: Tdescrsetfunc;
    tp_dictoffset: longint;
    tp_init: Tinitproc;
    tp_alloc: Tallocfunc;
    tp_new: Tnewfunc;
    tp_free: Tpydestructor; // Low-level free-memory routine
    tp_is_gc: Tinquiry; // For PyObject_IS_GC
    tp_bases: PPyObject;
    tp_mro: PPyObject; // method resolution order
    tp_cache: PPyObject;
    tp_subclasses: PPyObject;
    tp_weaklist: PPyObject;
    //More spares
    tp_xxx7:        pointer;
    tp_xxx8:        pointer;
  end;

  PPyMethodChain = ^TPyMethodChain;
  TPyMethodChain = record
    methods: PPyMethodDef;
    link:    PPyMethodChain;
  end;

  PPyClassObject = ^TPyClassObject;
  TPyClassObject = object(TPyObject)
    cl_bases: PPyObject;      // A tuple of class objects
    cl_dict: PPyObject;       // A dictionary
    cl_name: PPyObject;       // A string
    // The following three are functions or NULL
    cl_getattr: PPyObject;
    cl_setattr: PPyObject;
    cl_delattr: PPyObject;
  end;

  PPyInstanceObject = ^TPyInstanceObject;
  TPyInstanceObject = object(TPyObject)
    in_class: PPyClassObject;      // The class object
    in_dict: PPyObject;           // A dictionary
  end;

{ Instance method objects are used for two purposes:
   (a) as bound instance methods (returned by instancename.methodname)
   (b) as unbound methods (returned by ClassName.methodname)
   In case (b), im_self is NULL
}

  PPyMethodObject = ^TPyMethodObject;
  TPyMethodObject = object(TPyObject)
    im_func: PPyObject;      // The function implementing the method
    im_self: PPyObject;      // The instance it is bound to, or NULL
    im_class: PPyObject;      // The class that defined the method
  end;

  // Bytecode object, compile.h
  PPyCodeObject = ^TPyCodeObject;
  TPyCodeObject = object(TPyObject)
    co_argcount: Integer;         // #arguments, except *args
    co_nlocals: Integer;         // #local variables
    co_stacksize: Integer;          // #entries needed for evaluation stack
    co_flags: Integer;         // CO_..., see below
    co_code: PPyObject;       // instruction opcodes (it hides a PyStringObject)
    co_consts: PPyObject;       // list (constants used)
    co_names: PPyObject;       // list of strings (names used)
    co_varnames: PPyObject;       // tuple of strings (local variable names)
    co_freevars: PPyObject;	      // tuple of strings (free variable names)
    co_cellvars: PPyObject;       // tuple of strings (cell variable names)
    // The rest doesn't count for hash/cmp
    co_filename: PPyObject;       // string (where it was loaded from)
    co_name: PPyObject;       // string (name, for reference)
    co_firstlineno: Integer;         // first source line number
    co_lnotab: PPyObject;       // string (encoding addr<->lineno mapping)
  end;

  // from pystate.h
  PPyInterpreterState = ^TPyInterpreterState;
  PPyThreadState = ^TPyThreadState;
  PPyFrameObject = ^TPyFrameObject;

  // Interpreter environments
  TPyInterpreterState = record
    next: PPyInterpreterState;
    tstate_head: PPyThreadState;

    modules: PPyObject;
    sysdict: PPyObject;
    builtins: PPyObject;

    checkinterval: integer;
  end;

  // Thread specific information
  TPyThreadState = record
    next: PPyThreadState;
    interp: PPyInterpreterState;

    frame: PPyFrameObject;
    recursion_depth: integer;
    ticker: integer;
    tracing: integer;

    sys_profilefunc: PPyObject;
    sys_tracefunc: PPyObject;

    curexc_type: PPyObject;
    curexc_value: PPyObject;
    curexc_traceback: PPyObject;

    exc_type: PPyObject;
    exc_value: PPyObject;
    exc_traceback: PPyObject;

    dict: PPyObject;
  end;

  // from frameobject.h

  PPyTryBlock = ^TPyTryBlock;
  TPyTryBlock = record
    b_type: Integer;       // what kind of block this is
    b_handler: Integer;       // where to jump to find handler
    b_level: Integer;       // value stack level to pop to
  end;

  CO_MAXBLOCKS  = 0..19;
  TPyFrameObject = object(TPyObject)
    // start of the VAR_HEAD of an object
    ob_size: Integer;           // Number of items in variable part
    // End of the Head of an object
    f_back: PPyFrameObject;    // previous frame, or NULL
    f_code: PPyCodeObject;     // code segment
    f_builtins: PPyObject;         // builtin symbol table (PyDictObject)
    f_globals: PPyObject;         // global symbol table (PyDictObject)
    f_locals: PPyObject;         // local symbol table (PyDictObject)
    f_valuestack: PPPyObject;        // points after the last local
    (* Next free slot in f_valuestack.  Frame creation sets to f_valuestack.
       Frame evaluation usually NULLs it, but a frame that yields sets it
       to the current stack top. *)
    f_stacktop: PPPyObject;
    f_trace: PPyObject;         // Trace function
    f_exc_type, f_exc_value, f_exc_traceback: PPyObject;
    f_tstate: PPyThreadState;
    f_lasti: Integer;           // Last instruction if called
    f_lineno: Integer;           // Current line number
    f_restricted: Integer;           // Flag set if restricted operations
                                      // in this scope
    f_iblock: Integer;           // index in f_blockstack
    f_blockstack: array[CO_MAXBLOCKS] of PyTryBlock; // for try and loop blocks
    f_nlocals: Integer;           // number of locals
    f_ncells: Integer;
    f_nfreevars: Integer;
    f_stacksize: Integer;           // size of value stack
    f_localsplus: array[0..0] of PPyObject; // locals+stack, dynamically sized
  end;

  // From traceback.c
  PPyTraceBackObject = ^TPyTraceBackObject;
  TPyTraceBackObject = object(TPyObject)
    tb_next: PPyTraceBackObject;
    tb_frame: PPyFrameObject;
    tb_lasti: Integer;
    tb_lineno: Integer;
  end;

  // Parse tree node interface

  PNode = ^Tnode;
  Tnode = record
    n_type: smallint;
    n_str: PChar;
    n_lineno: smallint;
    n_nchildren: smallint;
    n_child: PNode;
  end;

  // From weakrefobject.h

  PPyWeakReference = ^TPyWeakReference;
  TPyWeakReference = object(TPyObject)
    wr_object: PPyObject;
    wr_callback: PPyObject;
    hash: longint;
    wr_prev: PPyWeakReference;
    wr_next: PPyWeakReference;
  end;

  // from datetime.h


{* Fields are packed into successive bytes, each viewed as unsigned and
 * big-endian, unless otherwise noted:
 *
 * byte offset
 *  0 		year     2 bytes, 1-9999
 *  2	  	month    1 byte,  1-12
 *  3 		day      1 byte,  1-31
 *  4     hour     1 byte,  0-23
 *  5 		minute   1 byte,  0-59
 *  6 		second   1 byte,  0-59
 *  7 		usecond  3 bytes, 0-999999
 * 10
 *}

const
  { # of bytes for year, month, and day. }
  PyDateTime_DATE_DATASIZE = 4;

  { # of bytes for hour, minute, second, and usecond. }
  PyDateTime_TIME_DATASIZE = 6;

  { # of bytes for year, month, day, hour, minute, second, and usecond. }
  PyDateTime_DATETIME_DATASIZE = 10;
type
  TPyDateTime_Delta = object(TPyObject)
    hashcode: Integer;  // -1 when unknown
    days: Integer;  // -MAX_DELTA_DAYS <= days <= MAX_DELTA_DAYS
    seconds: Integer;  // 0 <= seconds < 24*3600 is invariant
    microseconds: Integer;  // 0 <= microseconds < 1000000 is invariant
  end;
  PPyDateTime_Delta = ^TPyDateTime_Delta;

  TPyDateTime_TZInfo = object(TPyObject) // a pure abstract base clase
  end;
  PPyDateTime_TZInfo = ^TPyDateTime_TZInfo;

{
/* The datetime and time types have hashcodes, and an optional tzinfo member,
 * present if and only if hastzinfo is true.
 */
#define _PyTZINFO_HEAD		\
	PyObject_HEAD		\
	long hashcode;		\
	char hastzinfo;		/* boolean flag */
}

{* No _PyDateTime_BaseTZInfo is allocated; it's just to have something
 * convenient to cast to, when getting at the hastzinfo member of objects
 * starting with _PyTZINFO_HEAD.
 *}
  TPyDateTime_BaseTZInfo = object(TPyObject)
    hashcode: Integer;
    hastzinfo: bool;  // boolean flag
  end;
  PPyDateTime_BaseTZInfo = ^TPyDateTime_BaseTZInfo;

{* All time objects are of PyDateTime_TimeType, but that can be allocated
 * in two ways, with or without a tzinfo member.  Without is the same as
 * tzinfo == None, but consumes less memory.  _PyDateTime_BaseTime is an
 * internal struct used to allocate the right amount of space for the
 * "without" case.
 *}
{#define _PyDateTime_TIMEHEAD	\
	_PyTZINFO_HEAD		\
	unsigned char data[_PyDateTime_TIME_DATASIZE];
}

  TPyDateTime_BaseTime = object(TPyDateTime_BaseTZInfo) 
    data: array[0..Pred(PyDateTime_TIME_DATASIZE)] of Byte;
  end;
  PPyDateTime_BaseTime = ^TPyDateTime_BaseTime;

  TPyDateTime_Time = object(TPyDateTime_BaseTime) // hastzinfo true
    tzinfo: PPyObject;
  end;
  PPyDateTime_Time = ^PyDateTime_Time;

{* All datetime objects are of PyDateTime_DateTimeType, but that can be
 * allocated in two ways too, just like for time objects above.  In addition,
 * the plain date type is a base class for datetime, so it must also have
 * a hastzinfo member (although it's unused there).
 *}
  TPyDateTime_Date = object(TPyDateTime_BaseTZInfo) 
    data: array [0..Pred(PyDateTime_DATE_DATASIZE)] of Byte;
  end;
  PPyDateTime_Date = ^TPyDateTime_Date;

 {
#define _PyDateTime_DATETIMEHEAD	\
	_PyTZINFO_HEAD			\
	unsigned char data[_PyDateTime_DATETIME_DATASIZE];
}

  TPyDateTime_BaseDateTime = object(TPyDateTime_BaseTZInfo) // hastzinfo false
    data: array[0..Pred(PyDateTime_DATETIME_DATASIZE)] of Byte;
  end;
  PPyDateTime_BaseDateTime = ^TPyDateTime_BaseDateTime;

  TPyDateTime_DateTime = object(TPyDateTime_BaseTZInfo) // hastzinfo true
    data: array[0..Pred(PyDateTime_DATETIME_DATASIZE)] of Byte;
    tzinfo: PPyObject;
  end;
  PPyDateTime_DateTime = ^TPyDateTime_DateTime;


//#######################################################
//##                                                   ##
//##         New exception classes                     ##
//##                                                   ##
//#######################################################
(*
  // Python's exceptions
  EPythonError   = object(Exception)
      EName: String;
      EValue: String;
  end;
  EPyExecError   = object(EPythonError)
  end;

  // Standard exception classes of Python

/// jah 29-sep-2000: updated for python 2.0
///                   base classes updated according python documentation

{ Hierarchy of Python exceptions, Python 2.3, copied from <INSTALL>\Python\exceptions.c

Exception\n\
 |\n\
 +-- SystemExit\n\
 +-- StopIteration\n\
 +-- StandardError\n\
 |    |\n\
 |    +-- KeyboardInterrupt\n\
 |    +-- ImportError\n\
 |    +-- EnvironmentError\n\
 |    |    |\n\
 |    |    +-- IOError\n\
 |    |    +-- OSError\n\
 |    |         |\n\
 |    |         +-- WindowsError\n\
 |    |         +-- VMSError\n\
 |    |\n\
 |    +-- EOFError\n\
 |    +-- RuntimeError\n\
 |    |    |\n\
 |    |    +-- NotImplementedError\n\
 |    |\n\
 |    +-- NameError\n\
 |    |    |\n\
 |    |    +-- UnboundLocalError\n\
 |    |\n\
 |    +-- AttributeError\n\
 |    +-- SyntaxError\n\
 |    |    |\n\
 |    |    +-- IndentationError\n\
 |    |         |\n\
 |    |         +-- TabError\n\
 |    |\n\
 |    +-- TypeError\n\
 |    +-- AssertionError\n\
 |    +-- LookupError\n\
 |    |    |\n\
 |    |    +-- IndexError\n\
 |    |    +-- KeyError\n\
 |    |\n\
 |    +-- ArithmeticError\n\
 |    |    |\n\
 |    |    +-- OverflowError\n\
 |    |    +-- ZeroDivisionError\n\
 |    |    +-- FloatingPointError\n\
 |    |\n\
 |    +-- ValueError\n\
 |    |    |\n\
 |    |    +-- UnicodeError\n\
 |    |        |\n\
 |    |        +-- UnicodeEncodeError\n\
 |    |        +-- UnicodeDecodeError\n\
 |    |        +-- UnicodeTranslateError\n\
 |    |\n\
 |    +-- ReferenceError\n\
 |    +-- SystemError\n\
 |    +-- MemoryError\n\
 |\n\
 +---Warning\n\
      |\n\
      +-- UserWarning\n\
      +-- DeprecationWarning\n\
      +-- PendingDeprecationWarning\n\
      +-- SyntaxWarning\n\
      +-- OverflowWarning\n\
      +-- RuntimeWarning\n\
      +-- FutureWarning"
}
   EPyException = class (EPythonError);
   EPyStandardError = class (EPyException);
   EPyArithmeticError = class (EPyStandardError);
   EPyLookupError = class (EPyStandardError);
   EPyAssertionError = class (EPyStandardError);
   EPyAttributeError = class (EPyStandardError);
   EPyEOFError = class (EPyStandardError);
   EPyFloatingPointError = class (EPyArithmeticError);
   EPyEnvironmentError = class (EPyStandardError);
   EPyIOError = class (EPyEnvironmentError);
   EPyOSError = class (EPyEnvironmentError);
   EPyImportError = class (EPyStandardError);
   EPyIndexError = class (EPyLookupError);
   EPyKeyError = class (EPyLookupError);
   EPyKeyboardInterrupt = class (EPyStandardError);
   EPyMemoryError = class (EPyStandardError);
   EPyNameError = class (EPyStandardError);
   EPyOverflowError = class (EPyArithmeticError);
   EPyRuntimeError = class (EPyStandardError);
   EPyNotImplementedError = class (EPyRuntimeError);
   EPySyntaxError = class (EPyStandardError)
   public
      EFileName: string;
      ELineStr: string;
      ELineNumber: Integer;
      EOffset: Integer;
   end;
   EPyIndentationError = class (EPySyntaxError);
   EPyTabError = class (EPyIndentationError);
   EPySystemError = class (EPyStandardError);
   EPySystemExit = class (EPyException);
   EPyTypeError = class (EPyStandardError);
   EPyUnboundLocalError = class (EPyNameError);
   EPyValueError = class (EPyStandardError);
   EPyUnicodeError = class (EPyValueError);
   UnicodeEncodeError = class (EPyUnicodeError);
   UnicodeDecodeError = class (EPyUnicodeError);
   UnicodeTranslateError = class (EPyUnicodeError);
   EPyZeroDivisionError = class (EPyArithmeticError);
   EPyStopIteration = class(EPyException);
   EPyWarning = class (EPyException);
   EPyUserWarning = class (EPyWarning);
   EPyDeprecationWarning = class (EPyWarning);
   PendingDeprecationWarning = class (EPyWarning);
   FutureWarning = class (EPyWarning);
   EPySyntaxWarning = class (EPyWarning);
   EPyOverflowWarning = class (EPyWarning);
   EPyRuntimeWarning = class (EPyWarning);
   EPyReferenceError = class (EPyStandardError);
*)

var
    PyArg_Parse: function(args: PPyObject; format: PChar):
                     Integer; cdecl;// varargs; 
    PyArg_ParseTuple: function(args: PPyObject; format: PChar;
                              x1: Pointer = nil;
                              x2: Pointer = nil;
                              x3: Pointer = nil):
                     Integer; cdecl;// varargs
    Py_BuildValue: function(format: PChar): PPyObject; cdecl; // varargs
    PyCode_Addr2Line: function (co: PPyCodeObject; addrq: Integer): Integer; cdecl;
    DLL_Py_GetBuildInfo: function: PChar; cdecl;

    // define Python flags. See file pyDebug.h
    Py_DebugFlag: PInt;
    Py_VerboseFlag: PInt;
    Py_InteractiveFlag: PInt;
    Py_OptimizeFlag: PInt;
    Py_NoSiteFlag: PInt;
    Py_UseClassExceptionsFlag: PInt;
    Py_FrozenFlag: PInt;
    Py_TabcheckFlag: PInt;
    Py_UnicodeFlag: PInt;
    Py_IgnoreEnvironmentFlag: PInt;
    Py_DivisionWarningFlag: PInt;
    //_PySys_TraceFunc:    PPPyObject;
    //_PySys_ProfileFunc: PPPPyObject;

    PyImport_FrozenModules: PP_frozen;

    Py_None:            PPyObject;
    Py_Ellipsis:        PPyObject;
    Py_False:           PPyIntObject;
    Py_True:            PPyIntObject;
    Py_NotImplemented:  PPyObject;

    PyExc_AttributeError: PPPyObject;
    PyExc_EOFError: PPPyObject;
    PyExc_IOError: PPPyObject;
    PyExc_ImportError: PPPyObject;
    PyExc_IndexError: PPPyObject;
    PyExc_KeyError: PPPyObject;
    PyExc_KeyboardInterrupt: PPPyObject;
    PyExc_MemoryError: PPPyObject;
    PyExc_NameError: PPPyObject;
    PyExc_OverflowError: PPPyObject;
    PyExc_RuntimeError: PPPyObject;
    PyExc_SyntaxError: PPPyObject;
    PyExc_SystemError: PPPyObject;
    PyExc_SystemExit: PPPyObject;
    PyExc_TypeError: PPPyObject;
    PyExc_ValueError: PPPyObject;
    PyExc_ZeroDivisionError: PPPyObject;
    PyExc_ArithmeticError: PPPyObject;
    PyExc_Exception: PPPyObject;
    PyExc_FloatingPointError: PPPyObject;
    PyExc_LookupError: PPPyObject;
    PyExc_StandardError: PPPyObject;
    PyExc_AssertionError: PPPyObject;
    PyExc_EnvironmentError: PPPyObject;
    PyExc_IndentationError: PPPyObject;
    PyExc_MemoryErrorInst: PPPyObject;
    PyExc_NotImplementedError: PPPyObject;
    PyExc_OSError: PPPyObject;
    PyExc_TabError: PPPyObject;
    PyExc_UnboundLocalError: PPPyObject;
    PyExc_UnicodeError: PPPyObject;

    PyExc_Warning: PPPyObject;
    PyExc_DeprecationWarning: PPPyObject;
    PyExc_RuntimeWarning: PPPyObject;
    PyExc_SyntaxWarning: PPPyObject;
    PyExc_UserWarning: PPPyObject;
    PyExc_OverflowWarning: PPPyObject;
    PyExc_ReferenceError: PPPyObject;
    PyExc_StopIteration: PPPyObject;
    PyExc_FutureWarning: PPPyObject;
    PyExc_PendingDeprecationWarning: PPPyObject;
    PyExc_UnicodeDecodeError: PPPyObject;
    PyExc_UnicodeEncodeError: PPPyObject;
    PyExc_UnicodeTranslateError: PPPyObject;

    PyType_Type: PPyTypeObject;
    PyCFunction_Type: PPyTypeObject;
    PyCObject_Type: PPyTypeObject;
    PyClass_Type: PPyTypeObject;
    PyCode_Type: PPyTypeObject;
    PyComplex_Type: PPyTypeObject;
    PyDict_Type: PPyTypeObject;
    PyFile_Type: PPyTypeObject;
    PyFloat_Type: PPyTypeObject;
    PyFrame_Type: PPyTypeObject;
    PyFunction_Type: PPyTypeObject;
    PyInstance_Type: PPyTypeObject;
    PyInt_Type: PPyTypeObject;
    PyList_Type: PPyTypeObject;
    PyLong_Type: PPyTypeObject;
    PyMethod_Type: PPyTypeObject;
    PyModule_Type: PPyTypeObject;
    PyObject_Type: PPyTypeObject;
    PyRange_Type: PPyTypeObject;
    PySlice_Type: PPyTypeObject;
    PyString_Type: PPyTypeObject;
    PyTuple_Type: PPyTypeObject;

    PyBaseObject_Type: PPyTypeObject;
    PyBuffer_Type: PPyTypeObject;
    PyCallIter_Type: PPyTypeObject;
    PyCell_Type: PPyTypeObject;
    PyClassMethod_Type: PPyTypeObject;
    PyProperty_Type: PPyTypeObject;
    PySeqIter_Type: PPyTypeObject;
    PyStaticMethod_Type: PPyTypeObject;
    PySuper_Type: PPyTypeObject;
    PySymtableEntry_Type: PPyTypeObject;
    PyTraceBack_Type: PPyTypeObject;
    PyUnicode_Type: PPyTypeObject;
    PyWrapperDescr_Type: PPyTypeObject;

    PyBaseString_Type: PPyTypeObject;
    PyBool_Type: PPyTypeObject;
    PyEnum_Type: PPyTypeObject;

    //PyArg_GetObject: function(args: PPyObject; nargs, i: integer; p_a: PPPyObject): integer; cdecl;
    //PyArg_GetLong:   function(args: PPyObject; nargs, i: integer; p_a: PLong): integer; cdecl;
    //PyArg_GetShort:  function(args: PPyObject; nargs, i: integer; p_a: PShort): integer; cdecl;
    //PyArg_GetFloat:  function(args: PPyObject; nargs, i: integer; p_a: PFloat): integer; cdecl;
    //PyArg_GetString: function(args: PPyObject; nargs, i: integer; p_a: PString): integer; cdecl;
    //PyArgs_VaParse:  function (args: PPyObject; format: PChar; va_list: array of const): integer; cdecl;
    // Does not work!
    // Py_VaBuildValue: function (format: PChar; va_list: array of const): PPyObject; cdecl;
    //PyBuiltin_Init:     procedure; cdecl;

    PyComplex_FromCComplex: function(c: TPy_complex):PPyObject; cdecl;
    PyComplex_FromDoubles: function(realv,imag: double):PPyObject; cdecl;
    PyComplex_RealAsDouble: function(op: PPyObject): double; cdecl;
    PyComplex_ImagAsDouble: function(op: PPyObject): double; cdecl;
    PyComplex_AsCComplex: function(op: PPyObject): TPy_complex; cdecl;
    PyCFunction_GetFunction: function(ob: PPyObject): Pointer; cdecl;
    PyCFunction_GetSelf: function(ob: PPyObject): PPyObject; cdecl;
    PyCallable_Check: function(ob	: PPyObject): integer; cdecl;
    PyCObject_FromVoidPtr: function(cobj, destruct: Pointer): PPyObject; cdecl;
    PyCObject_AsVoidPtr: function(ob: PPyObject): Pointer; cdecl;
    PyClass_New: function (ob1,ob2,ob3:  PPyObject): PPyObject; cdecl;
    PyClass_IsSubclass: function (ob1, ob2: PPyObject): integer cdecl;

    Py_InitModule4: function(name: PChar; methods: PPyMethodDef; doc: PChar;
                              passthrough: PPyObject; Api_Version: Integer):PPyObject; cdecl;
    PyErr_BadArgument:  function: integer; cdecl;
    PyErr_BadInternalCall: procedure; cdecl;
    PyErr_CheckSignals: function: integer; cdecl;
    PyErr_Clear:        procedure; cdecl;
    PyErr_Fetch:        procedure(errtype, errvalue, errtraceback: PPPyObject); cdecl;
    PyErr_NoMemory: function: PPyObject; cdecl;
    PyErr_Occurred:     function: PPyObject; cdecl;
    PyErr_Print:        procedure; cdecl;
    PyErr_Restore:      procedure  (errtype, errvalue, errtraceback: PPyObject); cdecl;
    PyErr_SetFromErrno: function (ob:  PPyObject):PPyObject; cdecl;
    PyErr_SetNone:      procedure(value: PPyObject); cdecl;
    PyErr_SetObject:    procedure  (ob1, ob2	: PPyObject); cdecl;
    PyErr_SetString:    procedure(ErrorObject: PPyObject; text: PChar); cdecl;
    PyImport_GetModuleDict: function: PPyObject; cdecl;
    PyInt_FromLong:     function(x: LongInt):PPyObject; cdecl;
    Py_Initialize:      procedure; cdecl;
    Py_Exit:            procedure(RetVal: Integer); cdecl;
    PyEval_GetBuiltins: function: PPyObject; cdecl;
    PyDict_GetItem: function(mp, key: PPyObject):PPyObject; cdecl;
    PyDict_SetItem: function(mp, key, item:PPyObject):integer; cdecl;
    PyDict_DelItem: function(mp, key: PPyObject):integer; cdecl;
    PyDict_Clear: procedure(mp: PPyObject); cdecl;
    PyDict_Next: function(mp: PPyObject; pos: PInt; key, value: PPPyObject):integer; cdecl;
    PyDict_Keys: function(mp: PPyObject):PPyObject; cdecl;
    PyDict_Values: function(mp: PPyObject):PPyObject; cdecl;
    PyDict_Items: function(mp: PPyObject):PPyObject; cdecl;
    PyDict_Size: function(mp: PPyObject):integer; cdecl;
    PyDict_DelItemString: function(dp: PPyObject;key: PChar):integer; cdecl;
    PyDict_New: function: PPyObject; cdecl;
    PyDict_GetItemString: function(dp: PPyObject; key: PChar): PPyObject; cdecl;
    PyDict_SetItemString: function(dp: PPyObject; key: PChar; item: PPyObject):
                          Integer; cdecl;
    PyDictProxy_New: function (obj: PPyObject): PPyObject; cdecl;
    PyModule_GetDict:     function(module:PPyObject): PPyObject; cdecl;
    PyObject_Str:         function(v: PPyObject): PPyObject; cdecl;
    PyRun_String:         function(str: PChar; start: Integer; globals: PPyObject;
                                    locals: PPyObject): PPyObject; cdecl;
    PyRun_SimpleString:   function(str: PChar): Integer; cdecl;
    PyString_AsString:    function(ob: PPyObject): PChar; cdecl;
    PyString_FromString:  function(str: PChar): PPyObject; cdecl;
    PySys_SetArgv:        procedure(argc: Integer; argv: PPChar); cdecl;

{+ means, Grzegorz or me has tested his non object version of this function}
{+} PyCFunction_New: function(md:PPyMethodDef;ob:PPyObject):PPyObject; cdecl;
{+} PyEval_CallObject: function(ob1,ob2:PPyObject):PPyObject; cdecl;
{-} PyEval_CallObjectWithKeywords:function (ob1,ob2,ob3:PPyObject):PPyObject; cdecl;
{-} PyEval_GetFrame:function:PPyObject; cdecl;
{-} PyEval_GetGlobals:function:PPyObject; cdecl;
{-} PyEval_GetLocals:function:PPyObject; cdecl;
{-} //PyEval_GetOwner:function:PPyObject; cdecl;
{-} PyEval_GetRestricted:function:integer; cdecl;

{-} PyEval_InitThreads:procedure; cdecl;
{-} PyEval_RestoreThread:procedure(tstate: PPyThreadState); cdecl;
{-} PyEval_SaveThread:function:PPyThreadState; cdecl;

{-} PyFile_FromString:function (pc1,pc2:PChar):PPyObject; cdecl;
{-} PyFile_GetLine:function (ob:PPyObject;i:integer):PPyObject; cdecl;
{-} PyFile_Name:function (ob:PPyObject):PPyObject; cdecl;
{-} PyFile_SetBufSize:procedure(ob:PPyObject;i:integer); cdecl;
{-} PyFile_SoftSpace:function (ob:PPyObject;i:integer):integer; cdecl;
{-} PyFile_WriteObject:function (ob1,ob2:PPyObject;i:integer):integer; cdecl;
{-} PyFile_WriteString:procedure(s:PChar;ob:PPyObject); cdecl;
{+} PyFloat_AsDouble:function (ob:PPyObject):DOUBLE; cdecl;
{+} PyFloat_FromDouble:function (db:double):PPyObject; cdecl;
{-} PyFunction_GetCode:function (ob:PPyObject):PPyObject; cdecl;
{-} PyFunction_GetGlobals:function (ob:PPyObject):PPyObject; cdecl;
{-} PyFunction_New:function (ob1,ob2:PPyObject):PPyObject; cdecl;
{-} PyImport_AddModule:function (name:PChar):PPyObject; cdecl;
{-} PyImport_Cleanup:procedure; cdecl;
{-} PyImport_GetMagicNumber:function:LONGINT; cdecl;
{+} PyImport_ImportFrozenModule:function (key:PChar):integer; cdecl;
{+} PyImport_ImportModule:function (name:PChar):PPyObject; cdecl;
{+} PyImport_Import:function (name:PPyObject):PPyObject; cdecl;
{-} //PyImport_Init:procedure; cdecl;
{-} PyImport_ReloadModule:function (ob:PPyObject):PPyObject; cdecl;
{-} PyInstance_New:function (obClass, obArg, obKW:PPyObject):PPyObject; cdecl;
{+} PyInt_AsLong:function (ob:PPyObject):LONGINT; cdecl;
{-} PyList_Append:function (ob1,ob2:PPyObject):integer; cdecl;
{-} PyList_AsTuple:function (ob:PPyObject):PPyObject; cdecl;
{+} PyList_GetItem:function (ob:PPyObject;i:integer):PPyObject; cdecl;
{-} PyList_GetSlice:function (ob:PPyObject;i1,i2:integer):PPyObject; cdecl;
{-} PyList_Insert:function (dp:PPyObject;idx:Integer;item:PPyObject):integer; cdecl;
{-} PyList_New:function (size:integer):PPyObject; cdecl;
{-} PyList_Reverse:function (ob:PPyObject):integer; cdecl;
{-} PyList_SetItem:function (dp:PPyObject;idx:Integer;item:PPyObject):integer; cdecl;
{-} PyList_SetSlice:function (ob:PPyObject;i1,i2:integer;ob2:PPyObject):integer; cdecl;
{+} PyList_Size:function (ob:PPyObject):integer; cdecl;
{-} PyList_Sort:function (ob:PPyObject):integer; cdecl;
{-} PyLong_AsDouble:function (ob:PPyObject):DOUBLE; cdecl;
{+} PyLong_AsLong:function (ob:PPyObject):LONGINT; cdecl;
{+} PyLong_FromDouble:function (db:double):PPyObject; cdecl;
{+} PyLong_FromLong:function (l:longint):PPyObject; cdecl;
{-} PyLong_FromString:function (pc:PChar;var ppc:PChar;i:integer):PPyObject; cdecl;
{-} PyLong_FromUnsignedLong:function(val:cardinal): PPyObject; cdecl;
{-} PyLong_AsUnsignedLong:function(ob:PPyObject): Cardinal; cdecl;
{-} PyLong_FromUnicode:function(ob:PPyObject; a, b: integer): PPyObject; cdecl;
{-} PyLong_FromLongLong:function(val:Int64): PPyObject; cdecl;
{-} PyLong_AsLongLong:function(ob:PPyObject): Int64; cdecl;
{-} PyMapping_Check:function (ob:PPyObject):integer; cdecl;
{-} PyMapping_GetItemString:function (ob:PPyObject;key:PChar):PPyObject; cdecl;
{-} PyMapping_HasKey:function (ob,key:PPyObject):integer; cdecl;
{-} PyMapping_HasKeyString:function (ob:PPyObject;key:PChar):integer; cdecl;
{-} PyMapping_Length:function (ob:PPyObject):integer; cdecl;
{-} PyMapping_SetItemString:function (ob:PPyObject; key:PChar; value:PPyObject):integer; cdecl;
{-} PyMethod_Class:function (ob:PPyObject):PPyObject; cdecl;
{-} PyMethod_Function:function (ob:PPyObject):PPyObject; cdecl;
{-} PyMethod_New:function (ob1,ob2,ob3:PPyObject):PPyObject; cdecl;
{-} PyMethod_Self:function (ob:PPyObject):PPyObject; cdecl;
{-} PyModule_GetName:function (ob:PPyObject):PChar; cdecl;
{-} PyModule_New:function (key:PChar):PPyObject; cdecl;
{-} PyNumber_Absolute:function (ob:PPyObject):PPyObject; cdecl;
{-} PyNumber_Add:function (ob1,ob2:PPyObject):PPyObject; cdecl;
{-} PyNumber_And:function (ob1,ob2:PPyObject):PPyObject; cdecl;
{-} PyNumber_Check:function (ob:PPyObject):integer; cdecl;
{-} PyNumber_Coerce:function (var ob1,ob2:PPyObject):integer; cdecl;
{-} PyNumber_Divide:function (ob1,ob2:PPyObject):PPyObject; cdecl;
{-} PyNumber_FloorDivide:function (ob1,ob2:PPyObject):PPyObject; cdecl;
{-} PyNumber_TrueDivide:function (ob1,ob2:PPyObject):PPyObject; cdecl;
{-} PyNumber_Divmod:function (ob1,ob2:PPyObject):PPyObject; cdecl;
{-} PyNumber_Float:function (ob:PPyObject):PPyObject; cdecl;
{-} PyNumber_Int:function (ob:PPyObject):PPyObject; cdecl;
{-} PyNumber_Invert:function (ob:PPyObject):PPyObject; cdecl;
{-} PyNumber_Long:function (ob:PPyObject):PPyObject; cdecl;
{-} PyNumber_Lshift:function (ob1,ob2:PPyObject):PPyObject; cdecl;
{-} PyNumber_Multiply:function (ob1,ob2:PPyObject):PPyObject; cdecl;
{-} PyNumber_Negative:function (ob:PPyObject):PPyObject; cdecl;
{-} PyNumber_Or:function (ob1,ob2:PPyObject):PPyObject; cdecl;
{-} PyNumber_Positive:function (ob:PPyObject):PPyObject; cdecl;
{-} PyNumber_Power:function (ob1,ob2,ob3:PPyObject):PPyObject; cdecl;
{-} PyNumber_Remainder:function (ob1,ob2:PPyObject):PPyObject; cdecl;
{-} PyNumber_Rshift:function (ob1,ob2:PPyObject):PPyObject; cdecl;
{-} PyNumber_Subtract:function (ob1,ob2:PPyObject):PPyObject; cdecl;
{-} PyNumber_Xor:function (ob1,ob2:PPyObject):PPyObject; cdecl;
{-} PyOS_InitInterrupts:procedure; cdecl;
{-} PyOS_InterruptOccurred:function:integer; cdecl;
{-} PyObject_CallObject:function (ob,args:PPyObject):PPyObject; cdecl;
{-} PyObject_Compare:function (ob1,ob2:PPyObject):integer; cdecl;
{-} PyObject_GetAttr:function (ob1,ob2:PPyObject):PPyObject; cdecl;
{+} PyObject_GetAttrString:function (ob:PPyObject;c:PChar):PPyObject; cdecl;
{-} PyObject_GetItem:function (ob,key:PPyObject):PPyObject; cdecl;
{-} PyObject_DelItem:function (ob,key:PPyObject):PPyObject; cdecl;
{-} PyObject_HasAttrString:function (ob:PPyObject;key:PChar):integer; cdecl;
{-} PyObject_Hash:function (ob:PPyObject):LONGINT; cdecl;
{-} PyObject_IsTrue:function (ob:PPyObject):integer; cdecl;
{-} PyObject_Length:function (ob:PPyObject):integer; cdecl;
{-} PyObject_Repr:function (ob:PPyObject):PPyObject; cdecl;
{-} PyObject_SetAttr:function (ob1,ob2,ob3:PPyObject):integer; cdecl;
{-} PyObject_SetAttrString:function (ob:PPyObject;key:Pchar;value:PPyObject):integer; cdecl;
{-} PyObject_SetItem:function (ob1,ob2,ob3:PPyObject):integer; cdecl;
{-} PyObject_Init:function (ob:PPyObject; t:PPyTypeObject):PPyObject; cdecl;
{-} PyObject_InitVar:function (ob:PPyObject; t:PPyTypeObject; size:integer):PPyObject; cdecl;
{-} PyObject_New:function (t:PPyTypeObject):PPyObject; cdecl;
{-} PyObject_NewVar:function (t:PPyTypeObject; size:integer):PPyObject; cdecl;
    PyObject_Free:procedure (ob:PPyObject); cdecl;
{-} PyObject_IsInstance:function (inst, cls:PPyObject):integer; cdecl;
{-} PyObject_IsSubclass:function (derived, cls:PPyObject):integer; cdecl;
    PyObject_GenericGetAttr:function (obj, name: PPyObject): PPyObject; cdecl;
    PyObject_GenericSetAttr:function (obj, name, value: PPyObject): Integer; cdecl;
{-} PyObject_GC_Malloc:function (size:integer):PPyObject; cdecl;
{-} PyObject_GC_New:function (t:PPyTypeObject):PPyObject; cdecl;
{-} PyObject_GC_NewVar:function (t:PPyTypeObject; size:integer):PPyObject; cdecl;
{-} PyObject_GC_Resize:function (t:PPyObject; newsize:integer):PPyObject; cdecl;
{-} PyObject_GC_Del:procedure (ob:PPyObject); cdecl;
{-} PyObject_GC_Track:procedure (ob:PPyObject); cdecl;
{-} PyObject_GC_UnTrack:procedure (ob:PPyObject); cdecl;
{-} PyRange_New:function (l1,l2,l3:longint;i:integer):PPyObject; cdecl;
{-} PySequence_Check:function (ob:PPyObject):integer; cdecl;
{-} PySequence_Concat:function (ob1,ob2:PPyObject):PPyObject; cdecl;
{-} PySequence_Count:function (ob1,ob2:PPyObject):integer; cdecl;
{-} PySequence_GetItem:function (ob:PPyObject;i:integer):PPyObject; cdecl;
{-} PySequence_GetSlice:function (ob:PPyObject;i1,i2:integer):PPyObject; cdecl;
{-} PySequence_In:function (ob1,ob2:PPyObject):integer; cdecl;
{-} PySequence_Index:function (ob1,ob2:PPyObject):integer; cdecl;
{-} PySequence_Length:function (ob:PPyObject):integer; cdecl;
{-} PySequence_Repeat:function (ob:PPyObject;count:integer):PPyObject; cdecl;
{-} PySequence_SetItem:function (ob:PPyObject;i:integer;value:PPyObject):integer; cdecl;
{-} PySequence_SetSlice:function (ob:PPyObject;i1,i2:integer;value:PPyObject):integer; cdecl;
{-} PySequence_DelSlice:function (ob:PPyObject;i1,i2:integer):integer; cdecl;
{-} PySequence_Tuple:function (ob:PPyObject):PPyObject; cdecl;
{-} PySequence_Contains:function (ob, value:PPyObject):integer; cdecl;
{-} PySlice_GetIndices:function (ob:PPySliceObject;length:integer;var start,stop,step:integer):integer; cdecl;
{-} PySlice_GetIndicesEx:function (ob:PPySliceObject;length:integer;var start,stop,step,slicelength:integer):integer; cdecl;
{-} PySlice_New:function (start,stop,step:PPyObject):PPyObject; cdecl;
{-} PyString_Concat:procedure(var ob1:PPyObject;ob2:PPyObject); cdecl;
{-} PyString_ConcatAndDel:procedure(var ob1:PPyObject;ob2:PPyObject); cdecl;
{-} PyString_Format:function (ob1,ob2:PPyObject):PPyObject; cdecl;
{-} PyString_FromStringAndSize:function (s:PChar;i:integer):PPyObject; cdecl;
{-} PyString_Size:function (ob:PPyObject):integer; cdecl;
{-} PyString_DecodeEscape:function(s:PChar; len:integer; errors:PChar; unicode:integer; recode_encoding:PChar):PPyObject; cdecl;
{-} PyString_Repr:function(ob:PPyObject; smartquotes:integer):PPyObject; cdecl;
{+} PySys_GetObject:function (s:PChar):PPyObject; cdecl;
{-} //PySys_Init:procedure; cdecl;
{-} PySys_SetObject:function (s:PChar;ob:PPyObject):integer; cdecl;
{-} PySys_SetPath:procedure(path:PChar); cdecl;
{-} //PyTraceBack_Fetch:function:PPyObject; cdecl;
{-} PyTraceBack_Here:function (p:pointer):integer; cdecl;
{-} PyTraceBack_Print:function (ob1,ob2:PPyObject):integer; cdecl;
{-} //PyTraceBack_Store:function (ob:PPyObject):integer; cdecl;
{+} PyTuple_GetItem:function (ob:PPyObject;i:integer):PPyObject; cdecl;
{-} PyTuple_GetSlice:function (ob:PPyObject;i1,i2:integer):PPyObject; cdecl;
{+} PyTuple_New:function (size:Integer):PPyObject; cdecl;
{+} PyTuple_SetItem:function (ob:PPyObject;key:integer;value:PPyObject):integer; cdecl;
{+} PyTuple_Size:function (ob:PPyObject):integer; cdecl;
{+} PyType_IsSubtype:function (a, b: PPyTypeObject):integer; cdecl;
    PyType_GenericAlloc:function(atype: PPyTypeObject; nitems:Integer): PPyObject; cdecl;
    PyType_GenericNew:function(atype: PPyTypeObject; args, kwds: PPyObject): PPyObject; cdecl;
    PyType_Ready:function(atype: PPyTypeObject): integer; cdecl;
{+} PyUnicode_FromWideChar:function (const w:PWideChar; size:integer):PPyObject; cdecl;
{+} PyUnicode_AsWideChar:function (unicode: PPyObject; w:PWideChar; size:integer):integer; cdecl;
{-} PyUnicode_FromOrdinal:function (ordinal:integer):PPyObject; cdecl;
    PyWeakref_GetObject: function (ref: PPyObject): PPyObject; cdecl;
    PyWeakref_NewProxy: function (ob, callback: PPyObject): PPyObject; cdecl;
    PyWeakref_NewRef: function (ob, callback: PPyObject): PPyObject; cdecl;
    PyWrapper_New: function (ob1, ob2: PPyObject): PPyObject; cdecl;
    PyBool_FromLong: function (ok: Integer): PPyObject; cdecl;
{-} Py_AtExit:function (proc: procedure):integer; cdecl;
{-} //Py_Cleanup:procedure; cdecl;
{-} Py_CompileString:function (s1,s2:PChar;i:integer):PPyObject; cdecl;
{-} Py_FatalError:procedure(s:PChar); cdecl;
{-} Py_FindMethod:function (md:PPyMethodDef;ob:PPyObject;key:PChar):PPyObject; cdecl;
{-} Py_FindMethodInChain:function (mc:PPyMethodChain;ob:PPyObject;key:PChar):PPyObject; cdecl;
{-} Py_FlushLine:procedure; cdecl;
{+} Py_Finalize: procedure; cdecl;
{-} PyErr_ExceptionMatches: function (exc: PPyObject): Integer; cdecl;
{-} PyErr_GivenExceptionMatches: function (raised_exc, exc: PPyObject): Integer; cdecl;
{-} PyEval_EvalCode: function (co: PPyCodeObject; globals, locals: PPyObject): PPyObject; cdecl;
{+} Py_GetVersion: function: PChar; cdecl;
{+} Py_GetCopyright: function: PChar; cdecl;
{+} Py_GetExecPrefix: function: PChar; cdecl;
{+} Py_GetPath: function: PChar; cdecl;
{+} Py_GetPrefix: function: PChar; cdecl;
{+} Py_GetProgramName: function: PChar; cdecl;

{-} PyParser_SimpleParseString: function (str: PChar; start: Integer): PNode; cdecl;
{-} PyNode_Free: procedure(n: PNode); cdecl;
{-} PyErr_NewException: function (name: PChar; base, dict: PPyObject): PPyObject; cdecl;
{-} Py_Malloc: function (size: Integer): Pointer;
{-} PyMem_Malloc: function (size: Integer): Pointer;
{-} PyObject_CallMethod: function (obj: PPyObject; method, format: PChar): PPyObject; cdecl;

{New exported Objects in Python 1.5}
    Py_SetProgramName: procedure(name: PChar); cdecl;
    Py_IsInitialized: function: integer; cdecl;
    Py_GetProgramFullPath: function: PChar; cdecl;
    Py_NewInterpreter: function: PPyThreadState; cdecl;
    Py_EndInterpreter: procedure(tstate: PPyThreadState); cdecl;
    PyEval_AcquireLock: procedure; cdecl;
    PyEval_ReleaseLock: procedure; cdecl;
    PyEval_AcquireThread: procedure(tstate: PPyThreadState); cdecl;
    PyEval_ReleaseThread: procedure(tstate: PPyThreadState); cdecl;
    PyInterpreterState_New: function: PPyInterpreterState; cdecl;
    PyInterpreterState_Clear: procedure(interp: PPyInterpreterState); cdecl;
    PyInterpreterState_Delete: procedure(interp: PPyInterpreterState); cdecl;
    PyThreadState_New: function (interp: PPyInterpreterState): PPyThreadState; cdecl;
    PyThreadState_Clear: procedure(tstate: PPyThreadState); cdecl;
    PyThreadState_Delete: procedure(tstate: PPyThreadState); cdecl;
    PyThreadState_Get: function: PPyThreadState; cdecl;
    PyThreadState_Swap: function (tstate: PPyThreadState): PPyThreadState; cdecl;

{Further exported Objects, may be implemented later}
{
    PyCode_New: Pointer;
    PyErr_SetInterrupt: Pointer;
    PyFile_AsFile: Pointer;
    PyFile_FromFile: Pointer;
    PyFloat_AsString: Pointer;
    PyFrame_BlockPop: Pointer;
    PyFrame_BlockSetup: Pointer;
    PyFrame_ExtendStack: Pointer;
    PyFrame_FastToLocals: Pointer;
    PyFrame_LocalsToFast: Pointer;
    PyFrame_New: Pointer;
    PyGrammar_AddAccelerators: Pointer;
    PyGrammar_FindDFA: Pointer;
    PyGrammar_LabelRepr: Pointer;
    PyInstance_DoBinOp: Pointer;
    PyInt_GetMax: Pointer;
    PyMarshal_Init: Pointer;
    PyMarshal_ReadLongFromFile: Pointer;
    PyMarshal_ReadObjectFromFile: Pointer;
    PyMarshal_ReadObjectFromString: Pointer;
    PyMarshal_WriteLongToFile: Pointer;
    PyMarshal_WriteObjectToFile: Pointer;
    PyMember_Get: Pointer;
    PyMember_Set: Pointer;
    PyNode_AddChild: Pointer;
    PyNode_Compile: Pointer;
    PyNode_New: Pointer;
    PyOS_GetLastModificationTime: Pointer;
    PyOS_Readline: Pointer;
    PyOS_strtol: Pointer;
    PyOS_strtoul: Pointer;
    PyObject_CallFunction: Pointer;
    PyObject_CallMethod: Pointer;
    PyObject_Print: Pointer;
    PyParser_AddToken: Pointer;
    PyParser_Delete: Pointer;
    PyParser_New: Pointer;
    PyParser_ParseFile: Pointer;
    PyParser_ParseString: Pointer;
    PyParser_SimpleParseFile: Pointer;
    PyRun_AnyFile: Pointer;
    PyRun_File: Pointer;
    PyRun_InteractiveLoop: Pointer;
    PyRun_InteractiveOne: Pointer;
    PyRun_SimpleFile: Pointer;
    PySys_GetFile: Pointer;
    PyToken_OneChar: Pointer;
    PyToken_TwoChars: Pointer;
    PyTokenizer_Free: Pointer;
    PyTokenizer_FromFile: Pointer;
    PyTokenizer_FromString: Pointer;
    PyTokenizer_Get: Pointer;
    Py_Main: Pointer;
    _PyObject_NewVar: Pointer;
    _PyParser_Grammar: Pointer;
    _PyParser_TokenNames: Pointer;
    _PyThread_Started: Pointer;
    _Py_c_diff: Pointer;
    _Py_c_neg: Pointer;
    _Py_c_pow: Pointer;
    _Py_c_prod: Pointer;
    _Py_c_quot: Pointer;
    _Py_c_sum: Pointer;
}
// functions redefined in Delphi
procedure Py_INCREF(op: PPyObject);
procedure Py_DECREF(op: PPyObject);
procedure Py_XINCREF(op: PPyObject);
procedure Py_XDECREF(op: PPyObject);

// This function handles all cardinals, pointer types (with no adjustment of pointers!)
// (Extended) floats, which are handled as Python doubles and currencies, handled
// as (normalized) Python doubles.
function PyImport_ExecCodeModule(const name: String; codeobject: PPyObject): PPyObject;
function PyString_Check(obj: PPyObject): Boolean;
function PyString_CheckExact(obj: PPyObject): Boolean;
function PyFloat_Check(obj: PPyObject): Boolean;
function PyFloat_CheckExact(obj: PPyObject): Boolean;
function PyInt_Check(obj: PPyObject): Boolean;
function PyInt_CheckExact(obj: PPyObject): Boolean;
function PyLong_Check(obj: PPyObject): Boolean;
function PyLong_CheckExact(obj: PPyObject): Boolean;
function PyTuple_Check(obj: PPyObject): Boolean;
function PyTuple_CheckExact(obj: PPyObject): Boolean;
function PyInstance_Check(obj: PPyObject): Boolean;
function PyClass_Check(obj: PPyObject): Boolean;
function PyMethod_Check(obj: PPyObject): Boolean;
function PyList_Check(obj: PPyObject): Boolean;
function PyList_CheckExact(obj: PPyObject): Boolean;
function PyDict_Check(obj: PPyObject): Boolean;
function PyDict_CheckExact(obj: PPyObject): Boolean;
function PyModule_Check(obj: PPyObject): Boolean;
function PyModule_CheckExact(obj: PPyObject): Boolean;
function PySlice_Check(obj: PPyObject): Boolean;
function PyFunction_Check(obj: PPyObject): Boolean;
function PyUnicode_Check(obj: PPyObject): Boolean;
function PyUnicode_CheckExact(obj: PPyObject): Boolean;
function PyType_IS_GC(t: PPyTypeObject): Boolean;
function PyObject_IS_GC(obj: PPyObject): Boolean;
function PyWeakref_Check(obj: PPyObject): Boolean;
function PyWeakref_CheckRef(obj: PPyObject): Boolean;
function PyWeakref_CheckProxy(obj: PPyObject): Boolean;
function PyBool_Check(obj: PPyObject): Boolean;
function PyBaseString_Check(obj: PPyObject): Boolean;
function PyEnum_Check(obj: PPyObject): Boolean;
function PyObject_TypeCheck(obj:PPyObject; t:PPyTypeObject): Boolean;
function Py_InitModule(const name: PChar; md: PPyMethodDef): PPyObject;

function  PyType_HasFeature(AType: PPyTypeObject; AFlag: Integer): Boolean;

implementation

procedure Py_INCREF(op: PPyObject);
begin
  Inc(op.ob_refcnt);
end;

procedure Py_DECREF(op: PPyObject);
begin
  Dec(op.ob_refcnt);
  if op.ob_refcnt = 0 then begin
    op.ob_type.tp_dealloc(op);
  end;
end;

procedure Py_XINCREF(op: PPyObject);
begin
  if op <> nil then Py_INCREF(op);
end;

procedure Py_XDECREF(op: PPyObject);
begin
  if op <> nil then Py_DECREF(op);
end;

function PyImport_ExecCodeModule(const name: String; 
             codeobject: PPyObject): PPyObject;
var
  m, d, v, modules: PPyObject;
begin
  m:= PyImport_AddModule(PChar(name));
  if m = nil then
    begin
      Result:= nil;
      Exit;
    end;
  d:= PyModule_GetDict(m);
  if PyDict_GetItemString(d, '__builtins__') = nil then
    begin
      if PyDict_SetItemString(d, '__builtins__', PyEval_GetBuiltins) <> 0 then
        begin
          Result:= nil;
          Exit;
        end;
    end;
  // Remember the fielname as the __file__ attribute
  if PyDict_SetItemString(d, '__file__', PPyCodeObject(codeobject).co_filename) <> 0 then
    PyErr_Clear(); // Not important enough to report
  v:= PyEval_EvalCode(PPyCodeObject(codeobject), d, d); // XXX owner ?
  if v = nil then
    begin
      Result:= nil;
      Exit;
    end;
  Py_XDECREF(v);
  modules:= PyImport_GetModuleDict();
  if PyDict_GetItemString(modules, PChar(name)) = nil then
    begin
      PyErr_SetString(PyExc_ImportError^, PChar(Format('Loaded module %.200s not found in sys.modules', [name])));
      Result:= nil;
      Exit;
    end;
  Py_XINCREF(m);
  Result:= m;
end;

function PyString_Check(obj: PPyObject): Boolean;
begin
  Result:= PyObject_TypeCheck(obj, PyString_Type);
end;

function PyString_CheckExact(obj: PPyObject): Boolean;
begin
  Result:= (obj <> nil) and (obj.ob_type = PPyTypeObject(PyString_Type));
end;

function PyFloat_Check(obj: PPyObject): Boolean;
begin
  Result:= PyObject_TypeCheck(obj, PyFloat_Type);
end;

function PyFloat_CheckExact(obj: PPyObject): Boolean;
begin
  Result:= (obj <> nil) and (obj.ob_type = PPyTypeObject(PyFloat_Type));
end;

function PyInt_Check(obj: PPyObject): Boolean;
begin
  Result:= PyObject_TypeCheck(obj, PyInt_Type);
end;

function PyInt_CheckExact(obj: PPyObject): Boolean;
begin
  Result:= (obj <> nil) and (obj.ob_type = PPyTypeObject(PyInt_Type));
end;

function PyLong_Check(obj: PPyObject): Boolean;
begin
  Result:= PyObject_TypeCheck(obj, PyLong_Type);
end;

function PyLong_CheckExact(obj: PPyObject): Boolean;
begin
  Result:= (obj <> nil) and (obj.ob_type = PPyTypeObject(PyLong_Type));
end;

function PyTuple_Check(obj: PPyObject): Boolean;
begin
  Result:= PyObject_TypeCheck(obj, PyTuple_Type);
end;

function PyTuple_CheckExact(obj: PPyObject): Boolean;
begin
  Result:= ( obj<> nil) and (obj^.ob_type = PPyTypeObject(PyTuple_Type));
end;

function PyInstance_Check(obj: PPyObject): Boolean;
begin
  Result:= (obj <> nil) and (obj^.ob_type = PPyTypeObject(PyInstance_Type));
end;

function PyClass_Check(obj: PPyObject): Boolean;
begin
  Result:= ( obj<> nil) and (obj^.ob_type = PPyTypeObject(PyClass_Type));
end;

function PyMethod_Check(obj: PPyObject): Boolean;
begin
  Result:= (obj <> nil) and (obj^.ob_type = PPyTypeObject(PyMethod_Type));
end;

function PyList_Check(obj: PPyObject): Boolean;
begin
  Result:= PyObject_TypeCheck(obj, PyList_Type);
end;

function PyList_CheckExact(obj: PPyObject): Boolean;
begin
  Result:= (obj<>nil) and (obj^.ob_type = PPyTypeObject(PyList_Type));
end;

function PyDict_Check(obj: PPyObject): Boolean;
begin
  Result:= PyObject_TypeCheck(obj, PyDict_Type);
end;

function PyDict_CheckExact(obj: PPyObject): Boolean;
begin
  Result:= (obj<>nil) and (obj^.ob_type = PPyTypeObject(PyDict_Type));
end;

function PyModule_Check(obj: PPyObject): Boolean;
begin
  Result:= PyObject_TypeCheck(obj, PyModule_Type);
end;

function PyModule_CheckExact(obj: PPyObject): Boolean;
begin
  Result:= (obj<>nil) and (obj^.ob_type = PPyTypeObject(PyModule_Type));
end;

function PySlice_Check(obj: PPyObject): Boolean;
begin
  Result:= (obj<>nil) and (obj^.ob_type = PPyTypeObject(PySlice_Type));
end;

function PyFunction_Check(obj: PPyObject): Boolean;
begin
  Result:= (obj<>nil) and
    ((obj.ob_type = PPyTypeObject(PyCFunction_Type)) or
     (obj.ob_type = PPyTypeObject(PyFunction_Type)));
end;

function PyUnicode_Check(obj: PPyObject): Boolean;
begin
  Result:= PyObject_TypeCheck(obj, PyUnicode_Type);
end;

function PyUnicode_CheckExact(obj: PPyObject): Boolean;
begin
  Result:= (obj<>nil) and (obj^.ob_type = PPyTypeObject(PyUnicode_Type));
end;

function PyType_IS_GC(t: PPyTypeObject): Boolean;
begin
  Result:= PyType_HasFeature(t, Py_TPFLAGS_HAVE_GC);
end;

function PyObject_IS_GC(obj: PPyObject): Boolean;
begin
  Result:= PyType_IS_GC(obj.ob_type) and
            ((obj.ob_type.tp_is_gc = nil) or (obj.ob_type.tp_is_gc(obj) = 1));
end;

function PyWeakref_Check(obj: PPyObject): Boolean;
begin
  Result:= (obj<>nil) and (PyWeakref_CheckRef(obj) or PyWeakref_CheckProxy(obj));
end;

function PyWeakref_CheckRef(obj: PPyObject): Boolean;
begin
  Result:= (obj<>nil) and (obj.ob_type = PPyTypeObject(PyWeakref_RefType));
end;

function PyWeakref_CheckProxy(obj: PPyObject): Boolean;
begin
  Result:= (obj<>nil) and
            ((obj.ob_type = PPyTypeObject(PyWeakref_ProxyType)) or
              (obj.ob_type = PPyTypeObject(PyWeakref_CallableProxyType)));
end;

function PyBool_Check(obj: PPyObject): Boolean;
begin
  Result:= (obj<>nil) and (obj.ob_type = PPyTypeObject(PyBool_Type));
end;

function PyBaseString_Check(obj: PPyObject): Boolean;
begin
  Result:= PyObject_TypeCheck(obj, PyBaseString_Type);
end;

function PyEnum_Check(obj: PPyObject): Boolean;
begin
  Result:= (obj<>nil) and (obj.ob_type = PPyTypeObject(PyEnum_Type));
end;

function PyObject_TypeCheck(obj: PPyObject; t: PPyTypeObject): Boolean;
begin
  Result:= (obj<>nil) and (obj.ob_type = t);
  if not Result and (obj<>nil) and (t<>nil) then
    Result:= PyType_IsSubtype(obj.ob_type, t) = 1;
end;

function Py_InitModule(const name: PChar; md: PPyMethodDef): PPyObject;
begin
  result:= Py_InitModule4(name, md, nil, nil, 1012);
end;

function PyType_HasFeature(AType: PPyTypeObject; AFlag: Integer): Boolean;
begin
  //(((t)->tp_flags & (f)) != 0)
  Result:= (AType.tp_flags and AFlag) <> 0;
end;

procedure init(lib: TLibHandle);
begin
  Py_DebugFlag               := getProcAddr(lib, 'Py_DebugFlag');
  Py_VerboseFlag             := getProcAddr(lib, 'Py_VerboseFlag');
  Py_InteractiveFlag         := getProcAddr(lib, 'Py_InteractiveFlag');
  Py_OptimizeFlag            := getProcAddr(lib, 'Py_OptimizeFlag');
  Py_NoSiteFlag              := getProcAddr(lib, 'Py_NoSiteFlag');
  Py_UseClassExceptionsFlag  := getProcAddr(lib, 'Py_UseClassExceptionsFlag');
  Py_FrozenFlag              := getProcAddr(lib, 'Py_FrozenFlag');
  Py_TabcheckFlag            := getProcAddr(lib, 'Py_TabcheckFlag');
  Py_UnicodeFlag             := getProcAddr(lib, 'Py_UnicodeFlag');

  Py_IgnoreEnvironmentFlag   := getProcAddr(lib, 'Py_IgnoreEnvironmentFlag');
  Py_DivisionWarningFlag     := getProcAddr(lib, 'Py_DivisionWarningFlag');
  Py_None                    := getProcAddr(lib, '_Py_NoneStruct');
  Py_Ellipsis                := getProcAddr(lib, '_Py_EllipsisObject');
  Py_False                   := getProcAddr(lib, '_Py_ZeroStruct');
  Py_True                    := getProcAddr(lib, '_Py_TrueStruct');
  Py_NotImplemented          := getProcAddr(lib, '_Py_NotImplementedStruct');

  PyImport_FrozenModules     := getProcAddr(lib, 'PyImport_FrozenModules');

  PyExc_AttributeError       := getProcAddr(lib, 'PyExc_AttributeError');
  PyExc_EOFError             := getProcAddr(lib, 'PyExc_EOFError');
  PyExc_IOError              := getProcAddr(lib, 'PyExc_IOError');
  PyExc_ImportError          := getProcAddr(lib, 'PyExc_ImportError');
  PyExc_IndexError           := getProcAddr(lib, 'PyExc_IndexError');
  PyExc_KeyError             := getProcAddr(lib, 'PyExc_KeyError');
  PyExc_KeyboardInterrupt    := getProcAddr(lib, 'PyExc_KeyboardInterrupt');
  PyExc_MemoryError          := getProcAddr(lib, 'PyExc_MemoryError');
  PyExc_NameError            := getProcAddr(lib, 'PyExc_NameError');
  PyExc_OverflowError        := getProcAddr(lib, 'PyExc_OverflowError');
  PyExc_RuntimeError         := getProcAddr(lib, 'PyExc_RuntimeError');
  PyExc_SyntaxError          := getProcAddr(lib, 'PyExc_SyntaxError');
  PyExc_SystemError          := getProcAddr(lib, 'PyExc_SystemError');
  PyExc_SystemExit           := getProcAddr(lib, 'PyExc_SystemExit');
  PyExc_TypeError            := getProcAddr(lib, 'PyExc_TypeError');
  PyExc_ValueError           := getProcAddr(lib, 'PyExc_ValueError');
  PyExc_ZeroDivisionError    := getProcAddr(lib, 'PyExc_ZeroDivisionError');
  PyExc_ArithmeticError      := getProcAddr(lib, 'PyExc_ArithmeticError');
  PyExc_Exception            := getProcAddr(lib, 'PyExc_Exception');
  PyExc_FloatingPointError   := getProcAddr(lib, 'PyExc_FloatingPointError');
  PyExc_LookupError          := getProcAddr(lib, 'PyExc_LookupError');
  PyExc_StandardError        := getProcAddr(lib, 'PyExc_StandardError');

  PyExc_AssertionError       := getProcAddr(lib, 'PyExc_AssertionError');
  PyExc_EnvironmentError     := getProcAddr(lib, 'PyExc_EnvironmentError');
  PyExc_IndentationError     := getProcAddr(lib, 'PyExc_IndentationError');
  PyExc_MemoryErrorInst      := getProcAddr(lib, 'PyExc_MemoryErrorInst');
  PyExc_NotImplementedError  := getProcAddr(lib, 'PyExc_NotImplementedError');
  PyExc_OSError              := getProcAddr(lib, 'PyExc_OSError');
  PyExc_TabError             := getProcAddr(lib, 'PyExc_TabError');
  PyExc_UnboundLocalError    := getProcAddr(lib, 'PyExc_UnboundLocalError');
  PyExc_UnicodeError         := getProcAddr(lib, 'PyExc_UnicodeError');

  PyExc_Warning              := getProcAddr(lib, 'PyExc_Warning');
  PyExc_DeprecationWarning   := getProcAddr(lib, 'PyExc_DeprecationWarning');
  PyExc_RuntimeWarning       := getProcAddr(lib, 'PyExc_RuntimeWarning');
  PyExc_SyntaxWarning        := getProcAddr(lib, 'PyExc_SyntaxWarning');
  PyExc_UserWarning          := getProcAddr(lib, 'PyExc_UserWarning');

  PyExc_OverflowWarning      := getProcAddr(lib, 'PyExc_OverflowWarning');
  PyExc_ReferenceError       := getProcAddr(lib, 'PyExc_ReferenceError');
  PyExc_StopIteration        := getProcAddr(lib, 'PyExc_StopIteration');

  PyExc_FutureWarning        := getProcAddr(lib, 'PyExc_FutureWarning');
  PyExc_PendingDeprecationWarning:= getProcAddr(lib, 'PyExc_PendingDeprecationWarning');
  PyExc_UnicodeDecodeError   := getProcAddr(lib, 'PyExc_UnicodeDecodeError');
  PyExc_UnicodeEncodeError   := getProcAddr(lib, 'PyExc_UnicodeEncodeError');
  PyExc_UnicodeTranslateError:= getProcAddr(lib, 'PyExc_UnicodeTranslateError');

  PyType_Type                := getProcAddr(lib, 'PyType_Type');
  PyCFunction_Type           := getProcAddr(lib, 'PyCFunction_Type');
  PyCObject_Type             := getProcAddr(lib, 'PyCObject_Type');
  PyClass_Type               := getProcAddr(lib, 'PyClass_Type');
  PyCode_Type                := getProcAddr(lib, 'PyCode_Type');
  PyComplex_Type             := getProcAddr(lib, 'PyComplex_Type');
  PyDict_Type                := getProcAddr(lib, 'PyDict_Type');
  PyFile_Type                := getProcAddr(lib, 'PyFile_Type');
  PyFloat_Type               := getProcAddr(lib, 'PyFloat_Type');
  PyFrame_Type               := getProcAddr(lib, 'PyFrame_Type');
  PyFunction_Type            := getProcAddr(lib, 'PyFunction_Type');
  PyInstance_Type            := getProcAddr(lib, 'PyInstance_Type');
  PyInt_Type                 := getProcAddr(lib, 'PyInt_Type');
  PyList_Type                := getProcAddr(lib, 'PyList_Type');
  PyLong_Type                := getProcAddr(lib, 'PyLong_Type');
  PyMethod_Type              := getProcAddr(lib, 'PyMethod_Type');
  PyModule_Type              := getProcAddr(lib, 'PyModule_Type');
  PyObject_Type              := getProcAddr(lib, 'PyObject_Type');
  PyRange_Type               := getProcAddr(lib, 'PyRange_Type');
  PySlice_Type               := getProcAddr(lib, 'PySlice_Type');
  PyString_Type              := getProcAddr(lib, 'PyString_Type');
  PyTuple_Type               := getProcAddr(lib, 'PyTuple_Type');

  PyUnicode_Type             := getProcAddr(lib, 'PyUnicode_Type');

  PyBaseObject_Type          := getProcAddr(lib, 'PyBaseObject_Type');
  PyBuffer_Type              := getProcAddr(lib, 'PyBuffer_Type');
  PyCallIter_Type            := getProcAddr(lib, 'PyCallIter_Type');
  PyCell_Type                := getProcAddr(lib, 'PyCell_Type');
  PyClassMethod_Type         := getProcAddr(lib, 'PyClassMethod_Type');
  PyProperty_Type            := getProcAddr(lib, 'PyProperty_Type');
  PySeqIter_Type             := getProcAddr(lib, 'PySeqIter_Type');
  PyStaticMethod_Type        := getProcAddr(lib, 'PyStaticMethod_Type');
  PySuper_Type               := getProcAddr(lib, 'PySuper_Type');
  PySymtableEntry_Type       := getProcAddr(lib, 'PySymtableEntry_Type');
  PyTraceBack_Type           := getProcAddr(lib, 'PyTraceBack_Type');
  PyWrapperDescr_Type        := getProcAddr(lib, 'PyWrapperDescr_Type');

  PyBaseString_Type          := getProcAddr(lib, 'PyBaseString_Type');
  PyBool_Type                := getProcAddr(lib, 'PyBool_Type');
  PyEnum_Type                := getProcAddr(lib, 'PyEnum_Type');


  //PyArg_GetObject           := getProcAddr(lib, 'PyArg_GetObject');
  //PyArg_GetLong             := getProcAddr(lib, 'PyArg_GetLong');
  //PyArg_GetShort            := getProcAddr(lib, 'PyArg_GetShort');
  //PyArg_GetFloat            := getProcAddr(lib, 'PyArg_GetFloat');
  //PyArg_GetString           := getProcAddr(lib, 'PyArg_GetString');
  //PyArgs_VaParse            := getProcAddr(lib, 'PyArgs_VaParse');
  //Py_VaBuildValue           := getProcAddr(lib, 'Py_VaBuildValue');
  //PyBuiltin_Init            := getProcAddr(lib, 'PyBuiltin_Init');
  PyComplex_FromCComplex    := getProcAddr(lib, 'PyComplex_FromCComplex');
  PyComplex_FromDoubles     := getProcAddr(lib, 'PyComplex_FromDoubles');
  PyComplex_RealAsDouble    := getProcAddr(lib, 'PyComplex_RealAsDouble');
  PyComplex_ImagAsDouble    := getProcAddr(lib, 'PyComplex_ImagAsDouble');
  PyComplex_AsCComplex      := getProcAddr(lib, 'PyComplex_AsCComplex');
  PyCFunction_GetFunction   := getProcAddr(lib, 'PyCFunction_GetFunction');
  PyCFunction_GetSelf       := getProcAddr(lib, 'PyCFunction_GetSelf');
  PyCallable_Check          := getProcAddr(lib, 'PyCallable_Check');
  PyCObject_FromVoidPtr     := getProcAddr(lib, 'PyCObject_FromVoidPtr');
  PyCObject_AsVoidPtr       := getProcAddr(lib, 'PyCObject_AsVoidPtr');
  PyClass_New               := getProcAddr(lib, 'PyClass_New');
  PyClass_IsSubclass        := getProcAddr(lib, 'PyClass_IsSubclass');
  PyDict_GetItem            := getProcAddr(lib, 'PyDict_GetItem');
  PyDict_SetItem            := getProcAddr(lib, 'PyDict_SetItem');
  PyDict_DelItem            := getProcAddr(lib, 'PyDict_DelItem');
  PyDict_Clear              := getProcAddr(lib, 'PyDict_Clear');
  PyDict_Next               := getProcAddr(lib, 'PyDict_Next');
  PyDict_Keys               := getProcAddr(lib, 'PyDict_Keys');
  PyDict_Values             := getProcAddr(lib, 'PyDict_Values');
  PyDict_Items              := getProcAddr(lib, 'PyDict_Items');
  PyDict_Size               := getProcAddr(lib, 'PyDict_Size');
  PyDict_DelItemString      := getProcAddr(lib, 'PyDict_DelItemString');
  PyDictProxy_New           := getProcAddr(lib, 'PyDictProxy_New');
  Py_InitModule4            := getProcAddr(lib, 'Py_InitModule4');
  PyErr_Print               := getProcAddr(lib, 'PyErr_Print');
  PyErr_SetNone             := getProcAddr(lib, 'PyErr_SetNone');
  PyErr_SetObject           := getProcAddr(lib, 'PyErr_SetObject');
  PyErr_Restore             := getProcAddr(lib, 'PyErr_Restore');
  PyErr_BadArgument         := getProcAddr(lib, 'PyErr_BadArgument');
  PyErr_NoMemory            := getProcAddr(lib, 'PyErr_NoMemory');
  PyErr_SetFromErrno        := getProcAddr(lib, 'PyErr_SetFromErrno');
  PyErr_BadInternalCall     := getProcAddr(lib, 'PyErr_BadInternalCall');
  PyErr_CheckSignals        := getProcAddr(lib, 'PyErr_CheckSignals');
  PyErr_Occurred            := getProcAddr(lib, 'PyErr_Occurred');
  PyErr_Clear               := getProcAddr(lib, 'PyErr_Clear');
  PyErr_Fetch               := getProcAddr(lib, 'PyErr_Fetch');
  PyErr_SetString           := getProcAddr(lib, 'PyErr_SetString');
  PyEval_GetBuiltins        := getProcAddr(lib, 'PyEval_GetBuiltins');
  PyImport_GetModuleDict    := getProcAddr(lib, 'PyImport_GetModuleDict');
  PyInt_FromLong            := getProcAddr(lib, 'PyInt_FromLong');
  PyArg_ParseTuple      := getProcAddr(lib, 'PyArg_ParseTuple');
  PyArg_Parse           := getProcAddr(lib, 'PyArg_Parse');
  Py_BuildValue         := getProcAddr(lib, 'Py_BuildValue');
  Py_Initialize             := getProcAddr(lib, 'Py_Initialize');
  PyDict_New                := getProcAddr(lib, 'PyDict_New');
  PyDict_SetItemString      := getProcAddr(lib, 'PyDict_SetItemString');
  PyModule_GetDict          := getProcAddr(lib, 'PyModule_GetDict');
  PyObject_Str              := getProcAddr(lib, 'PyObject_Str');
  PyRun_String              := getProcAddr(lib, 'PyRun_String');
  PyRun_SimpleString        := getProcAddr(lib, 'PyRun_SimpleString');
  PyDict_GetItemString      := getProcAddr(lib, 'PyDict_GetItemString');
  PyString_AsString         := getProcAddr(lib, 'PyString_AsString');
  PyString_FromString       := getProcAddr(lib, 'PyString_FromString');
  PySys_SetArgv             := getProcAddr(lib, 'PySys_SetArgv');
  Py_Exit                   := getProcAddr(lib, 'Py_Exit');

  PyCFunction_New           :=getProcAddr(lib, 'PyCFunction_New');
  PyEval_CallObject         :=getProcAddr(lib, 'PyEval_CallObject');
  PyEval_CallObjectWithKeywords:=getProcAddr(lib, 'PyEval_CallObjectWithKeywords');
  PyEval_GetFrame           :=getProcAddr(lib, 'PyEval_GetFrame');
  PyEval_GetGlobals         :=getProcAddr(lib, 'PyEval_GetGlobals');
  PyEval_GetLocals          :=getProcAddr(lib, 'PyEval_GetLocals');
  //PyEval_GetOwner           :=getProcAddr(lib, 'PyEval_GetOwner');
  PyEval_GetRestricted      :=getProcAddr(lib, 'PyEval_GetRestricted');
  PyEval_InitThreads        :=getProcAddr(lib, 'PyEval_InitThreads');
  PyEval_RestoreThread      :=getProcAddr(lib, 'PyEval_RestoreThread');
  PyEval_SaveThread         :=getProcAddr(lib, 'PyEval_SaveThread');
  PyFile_FromString         :=getProcAddr(lib, 'PyFile_FromString');
  PyFile_GetLine            :=getProcAddr(lib, 'PyFile_GetLine');
  PyFile_Name               :=getProcAddr(lib, 'PyFile_Name');
  PyFile_SetBufSize         :=getProcAddr(lib, 'PyFile_SetBufSize');
  PyFile_SoftSpace          :=getProcAddr(lib, 'PyFile_SoftSpace');
  PyFile_WriteObject        :=getProcAddr(lib, 'PyFile_WriteObject');
  PyFile_WriteString        :=getProcAddr(lib, 'PyFile_WriteString');
  PyFloat_AsDouble          :=getProcAddr(lib, 'PyFloat_AsDouble');
  PyFloat_FromDouble        :=getProcAddr(lib, 'PyFloat_FromDouble');
  PyFunction_GetCode        :=getProcAddr(lib, 'PyFunction_GetCode');
  PyFunction_GetGlobals     :=getProcAddr(lib, 'PyFunction_GetGlobals');
  PyFunction_New            :=getProcAddr(lib, 'PyFunction_New');
  PyImport_AddModule        :=getProcAddr(lib, 'PyImport_AddModule');
  PyImport_Cleanup          :=getProcAddr(lib, 'PyImport_Cleanup');
  PyImport_GetMagicNumber   :=getProcAddr(lib, 'PyImport_GetMagicNumber');
  PyImport_ImportFrozenModule:=getProcAddr(lib, 'PyImport_ImportFrozenModule');
  PyImport_ImportModule     :=getProcAddr(lib, 'PyImport_ImportModule');
  PyImport_Import           :=getProcAddr(lib, 'PyImport_Import');
  //@PyImport_Init             :=getProcAddr(lib, 'PyImport_Init');
  PyImport_ReloadModule     :=getProcAddr(lib, 'PyImport_ReloadModule');
  PyInstance_New            :=getProcAddr(lib, 'PyInstance_New');
  PyInt_AsLong              :=getProcAddr(lib, 'PyInt_AsLong');
  PyList_Append             :=getProcAddr(lib, 'PyList_Append');
  PyList_AsTuple            :=getProcAddr(lib, 'PyList_AsTuple');
  PyList_GetItem            :=getProcAddr(lib, 'PyList_GetItem');
  PyList_GetSlice           :=getProcAddr(lib, 'PyList_GetSlice');
  PyList_Insert             :=getProcAddr(lib, 'PyList_Insert');
  PyList_New                :=getProcAddr(lib, 'PyList_New');
  PyList_Reverse            :=getProcAddr(lib, 'PyList_Reverse');
  PyList_SetItem            :=getProcAddr(lib, 'PyList_SetItem');
  PyList_SetSlice           :=getProcAddr(lib, 'PyList_SetSlice');
  PyList_Size               :=getProcAddr(lib, 'PyList_Size');
  PyList_Sort               :=getProcAddr(lib, 'PyList_Sort');
  PyLong_AsDouble           :=getProcAddr(lib, 'PyLong_AsDouble');
  PyLong_AsLong             :=getProcAddr(lib, 'PyLong_AsLong');
  PyLong_FromDouble         :=getProcAddr(lib, 'PyLong_FromDouble');
  PyLong_FromLong           :=getProcAddr(lib, 'PyLong_FromLong');
  PyLong_FromString         :=getProcAddr(lib, 'PyLong_FromString');
  PyLong_FromString         :=getProcAddr(lib, 'PyLong_FromString');
  PyLong_FromUnsignedLong   :=getProcAddr(lib, 'PyLong_FromUnsignedLong');
  PyLong_AsUnsignedLong     :=getProcAddr(lib, 'PyLong_AsUnsignedLong');
  PyLong_FromUnicode        :=getProcAddr(lib, 'PyLong_FromUnicode');
  PyLong_FromLongLong       :=getProcAddr(lib, 'PyLong_FromLongLong');
  PyLong_AsLongLong         :=getProcAddr(lib, 'PyLong_AsLongLong');

  PyMapping_Check           :=getProcAddr(lib, 'PyMapping_Check');
  PyMapping_GetItemString   :=getProcAddr(lib, 'PyMapping_GetItemString');
  PyMapping_HasKey          :=getProcAddr(lib, 'PyMapping_HasKey');
  PyMapping_HasKeyString    :=getProcAddr(lib, 'PyMapping_HasKeyString');
  PyMapping_Length          :=getProcAddr(lib, 'PyMapping_Length');
  PyMapping_SetItemString   :=getProcAddr(lib, 'PyMapping_SetItemString');
  PyMethod_Class            :=getProcAddr(lib, 'PyMethod_Class');
  PyMethod_Function         :=getProcAddr(lib, 'PyMethod_Function');
  PyMethod_New              :=getProcAddr(lib, 'PyMethod_New');
  PyMethod_Self             :=getProcAddr(lib, 'PyMethod_Self');
  PyModule_GetName          :=getProcAddr(lib, 'PyModule_GetName');
  PyModule_New              :=getProcAddr(lib, 'PyModule_New');
  PyNumber_Absolute         :=getProcAddr(lib, 'PyNumber_Absolute');
  PyNumber_Add              :=getProcAddr(lib, 'PyNumber_Add');
  PyNumber_And              :=getProcAddr(lib, 'PyNumber_And');
  PyNumber_Check            :=getProcAddr(lib, 'PyNumber_Check');
  PyNumber_Coerce           :=getProcAddr(lib, 'PyNumber_Coerce');
  PyNumber_Divide           :=getProcAddr(lib, 'PyNumber_Divide');

  PyNumber_FloorDivide      :=getProcAddr(lib, 'PyNumber_FloorDivide');
  PyNumber_TrueDivide       :=getProcAddr(lib, 'PyNumber_TrueDivide');
  PyNumber_Divmod           :=getProcAddr(lib, 'PyNumber_Divmod');
  PyNumber_Float            :=getProcAddr(lib, 'PyNumber_Float');
  PyNumber_Int              :=getProcAddr(lib, 'PyNumber_Int');
  PyNumber_Invert           :=getProcAddr(lib, 'PyNumber_Invert');
  PyNumber_Long             :=getProcAddr(lib, 'PyNumber_Long');
  PyNumber_Lshift           :=getProcAddr(lib, 'PyNumber_Lshift');
  PyNumber_Multiply         :=getProcAddr(lib, 'PyNumber_Multiply');
  PyNumber_Negative         :=getProcAddr(lib, 'PyNumber_Negative');
  PyNumber_Or               :=getProcAddr(lib, 'PyNumber_Or');
  PyNumber_Positive         :=getProcAddr(lib, 'PyNumber_Positive');
  PyNumber_Power            :=getProcAddr(lib, 'PyNumber_Power');
  PyNumber_Remainder        :=getProcAddr(lib, 'PyNumber_Remainder');
  PyNumber_Rshift           :=getProcAddr(lib, 'PyNumber_Rshift');
  PyNumber_Subtract         :=getProcAddr(lib, 'PyNumber_Subtract');
  PyNumber_Xor              :=getProcAddr(lib, 'PyNumber_Xor');
  PyOS_InitInterrupts       :=getProcAddr(lib, 'PyOS_InitInterrupts');
  PyOS_InterruptOccurred    :=getProcAddr(lib, 'PyOS_InterruptOccurred');
  PyObject_CallObject       :=getProcAddr(lib, 'PyObject_CallObject');
  PyObject_Compare          :=getProcAddr(lib, 'PyObject_Compare');
  PyObject_GetAttr          :=getProcAddr(lib, 'PyObject_GetAttr');
  PyObject_GetAttrString    :=getProcAddr(lib, 'PyObject_GetAttrString');
  PyObject_GetItem          :=getProcAddr(lib, 'PyObject_GetItem');
  PyObject_DelItem          :=getProcAddr(lib, 'PyObject_DelItem');
  PyObject_HasAttrString    :=getProcAddr(lib, 'PyObject_HasAttrString');
  PyObject_Hash             :=getProcAddr(lib, 'PyObject_Hash');
  PyObject_IsTrue           :=getProcAddr(lib, 'PyObject_IsTrue');
  PyObject_Length           :=getProcAddr(lib, 'PyObject_Length');
  PyObject_Repr             :=getProcAddr(lib, 'PyObject_Repr');
  PyObject_SetAttr          :=getProcAddr(lib, 'PyObject_SetAttr');
  PyObject_SetAttrString    :=getProcAddr(lib, 'PyObject_SetAttrString');
  PyObject_SetItem          :=getProcAddr(lib, 'PyObject_SetItem');

  PyObject_Init             :=getProcAddr(lib, 'PyObject_Init');
  PyObject_InitVar          :=getProcAddr(lib, 'PyObject_InitVar');
  PyObject_New              :=getProcAddr(lib, '_PyObject_New');
  PyObject_NewVar           :=getProcAddr(lib, '_PyObject_NewVar');
  PyObject_Free             :=getProcAddr(lib, 'PyObject_Free');

  PyObject_IsInstance       :=getProcAddr(lib, 'PyObject_IsInstance');
  PyObject_IsSubclass       :=getProcAddr(lib, 'PyObject_IsSubclass');

  PyObject_GenericGetAttr   :=getProcAddr(lib, 'PyObject_GenericGetAttr');
  PyObject_GenericSetAttr   :=getProcAddr(lib, 'PyObject_GenericSetAttr');

  PyObject_GC_Malloc         :=getProcAddr(lib, '_PyObject_GC_Malloc');
  PyObject_GC_New            :=getProcAddr(lib, '_PyObject_GC_New');
  PyObject_GC_NewVar         :=getProcAddr(lib, '_PyObject_GC_NewVar');
  PyObject_GC_Resize         :=getProcAddr(lib, '_PyObject_GC_Resize');
  PyObject_GC_Del            :=getProcAddr(lib, 'PyObject_GC_Del');
  PyObject_GC_Track          :=getProcAddr(lib, 'PyObject_GC_Track');
  PyObject_GC_UnTrack        :=getProcAddr(lib, 'PyObject_GC_UnTrack');

  PyRange_New               :=getProcAddr(lib, 'PyRange_New');
  PySequence_Check          :=getProcAddr(lib, 'PySequence_Check');
  PySequence_Concat         :=getProcAddr(lib, 'PySequence_Concat');
  PySequence_Count          :=getProcAddr(lib, 'PySequence_Count');
  PySequence_GetItem        :=getProcAddr(lib, 'PySequence_GetItem');
  PySequence_GetSlice       :=getProcAddr(lib, 'PySequence_GetSlice');
  PySequence_In             :=getProcAddr(lib, 'PySequence_In');
  PySequence_Index          :=getProcAddr(lib, 'PySequence_Index');
  PySequence_Length         :=getProcAddr(lib, 'PySequence_Length');
  PySequence_Repeat         :=getProcAddr(lib, 'PySequence_Repeat');
  PySequence_SetItem        :=getProcAddr(lib, 'PySequence_SetItem');
  PySequence_SetSlice       :=getProcAddr(lib, 'PySequence_SetSlice');
  PySequence_DelSlice       :=getProcAddr(lib, 'PySequence_DelSlice');
  PySequence_Tuple          :=getProcAddr(lib, 'PySequence_Tuple');
  PySequence_Contains       :=getProcAddr(lib, 'PySequence_Contains');
  PySlice_GetIndices        :=getProcAddr(lib, 'PySlice_GetIndices');
  PySlice_GetIndicesEx      :=getProcAddr(lib, 'PySlice_GetIndicesEx');
  PySlice_New               :=getProcAddr(lib, 'PySlice_New');
  PyString_Concat           :=getProcAddr(lib, 'PyString_Concat');
  PyString_ConcatAndDel     :=getProcAddr(lib, 'PyString_ConcatAndDel');
  PyString_Format           :=getProcAddr(lib, 'PyString_Format');
  PyString_FromStringAndSize:=getProcAddr(lib, 'PyString_FromStringAndSize');
  PyString_Size             :=getProcAddr(lib, 'PyString_Size');
  PyString_DecodeEscape     :=getProcAddr(lib, 'PyString_DecodeEscape');
  PyString_Repr             :=getProcAddr(lib, 'PyString_Repr');
  PySys_GetObject           :=getProcAddr(lib, 'PySys_GetObject');
  //PySys_Init                :=getProcAddr(lib, 'PySys_Init');
  PySys_SetObject           :=getProcAddr(lib, 'PySys_SetObject');
  PySys_SetPath             :=getProcAddr(lib, 'PySys_SetPath');
  //PyTraceBack_Fetch         :=getProcAddr(lib, 'PyTraceBack_Fetch');
  PyTraceBack_Here          :=getProcAddr(lib, 'PyTraceBack_Here');
  PyTraceBack_Print         :=getProcAddr(lib, 'PyTraceBack_Print');
  //PyTraceBack_Store         :=getProcAddr(lib, 'PyTraceBack_Store');
  PyTuple_GetItem           :=getProcAddr(lib, 'PyTuple_GetItem');
  PyTuple_GetSlice          :=getProcAddr(lib, 'PyTuple_GetSlice');
  PyTuple_New               :=getProcAddr(lib, 'PyTuple_New');
  PyTuple_SetItem           :=getProcAddr(lib, 'PyTuple_SetItem');
  PyTuple_Size              :=getProcAddr(lib, 'PyTuple_Size');

  PyType_IsSubtype          :=getProcAddr(lib, 'PyType_IsSubtype');
  PyType_GenericAlloc       :=getProcAddr(lib, 'PyType_GenericAlloc');
  PyType_GenericNew         :=getProcAddr(lib, 'PyType_GenericNew');
  PyType_Ready              :=getProcAddr(lib, 'PyType_Ready');

  PyUnicode_FromWideChar    :=getProcAddr(lib, 'PyUnicodeUCS2_FromWideChar');
  PyUnicode_AsWideChar      :=getProcAddr(lib, 'PyUnicodeUCS2_AsWideChar');
  PyUnicode_FromOrdinal     :=getProcAddr(lib, 'PyUnicodeUCS2_FromOrdinal');

  PyWeakref_GetObject       :=getProcAddr(lib, 'PyWeakref_GetObject');
  PyWeakref_NewProxy        :=getProcAddr(lib, 'PyWeakref_NewProxy');
  PyWeakref_NewRef          :=getProcAddr(lib, 'PyWeakref_NewRef');
  PyWrapper_New             :=getProcAddr(lib, 'PyWrapper_New');

  PyBool_FromLong           :=getProcAddr(lib, 'PyBool_FromLong'); 

  Py_AtExit                 :=getProcAddr(lib, 'Py_AtExit');
  //Py_Cleanup                :=getProcAddr(lib, 'Py_Cleanup');
  Py_CompileString          :=getProcAddr(lib, 'Py_CompileString');
  Py_FatalError             :=getProcAddr(lib, 'Py_FatalError');
  Py_FindMethod             :=getProcAddr(lib, 'Py_FindMethod');
  Py_FindMethodInChain      :=getProcAddr(lib, 'Py_FindMethodInChain');
  Py_FlushLine              :=getProcAddr(lib, 'Py_FlushLine');
  Py_Finalize                :=getProcAddr(lib, 'Py_Finalize');
  PyCode_Addr2Line     := getProcAddr(lib, 'PyCode_Addr2Line');
  PyClass_IsSubclass         :=getProcAddr(lib, 'PyClass_IsSubclass');
  PyErr_ExceptionMatches     :=getProcAddr(lib, 'PyErr_ExceptionMatches');
  PyErr_GivenExceptionMatches:=getProcAddr(lib, 'PyErr_GivenExceptionMatches');
  PyEval_EvalCode            :=getProcAddr(lib, 'PyEval_EvalCode');
  Py_GetVersion              :=getProcAddr(lib, 'Py_GetVersion');
  Py_GetCopyright            :=getProcAddr(lib, 'Py_GetCopyright');
  Py_GetExecPrefix           :=getProcAddr(lib, 'Py_GetExecPrefix');
  Py_GetPath                 :=getProcAddr(lib, 'Py_GetPath');
  Py_GetPrefix               :=getProcAddr(lib, 'Py_GetPrefix');
  Py_GetProgramName          :=getProcAddr(lib, 'Py_GetProgramName');
  PyParser_SimpleParseString :=getProcAddr(lib, 'PyParser_SimpleParseString');
  PyNode_Free                :=getProcAddr(lib, 'PyNode_Free');
  PyErr_NewException         :=getProcAddr(lib, 'PyErr_NewException');
/// jah 29-sep-2000 : updated for python 2.0
///                   replaced Py_Malloc with PyMem_Malloc
///---   @Py_Malloc := Import ('Py_Malloc');
///+++   @Py_Malloc := Import ('PyMem_Malloc');
  Py_Malloc := getProcAddr(lib, 'PyMem_Malloc');
  PyMem_Malloc := getProcAddr(lib, 'PyMem_Malloc');
  PyObject_CallMethod        := getProcAddr(lib, 'PyObject_CallMethod');
  Py_SetProgramName        := getProcAddr(lib, 'Py_SetProgramName');
  Py_IsInitialized         := getProcAddr(lib, 'Py_IsInitialized');
  Py_GetProgramFullPath    := getProcAddr(lib, 'Py_GetProgramFullPath');
  DLL_Py_GetBuildInfo    := getProcAddr(lib, 'Py_GetBuildInfo');
  Py_NewInterpreter        := getProcAddr(lib, 'Py_NewInterpreter');
  Py_EndInterpreter        := getProcAddr(lib, 'Py_EndInterpreter');
  PyEval_AcquireLock       := getProcAddr(lib, 'PyEval_AcquireLock');
  PyEval_ReleaseLock       := getProcAddr(lib, 'PyEval_ReleaseLock');
  PyEval_AcquireThread     := getProcAddr(lib, 'PyEval_AcquireThread');
  PyEval_ReleaseThread     := getProcAddr(lib, 'PyEval_ReleaseThread');
  PyInterpreterState_New   := getProcAddr(lib, 'PyInterpreterState_New');
  PyInterpreterState_Clear := getProcAddr(lib, 'PyInterpreterState_Clear');
  PyInterpreterState_Delete:= getProcAddr(lib, 'PyInterpreterState_Delete');
  PyThreadState_New        := getProcAddr(lib, 'PyThreadState_New');
  PyThreadState_Clear      := getProcAddr(lib, 'PyThreadState_Clear');
  PyThreadState_Delete     := getProcAddr(lib, 'PyThreadState_Delete');
  PyThreadState_Get        := getProcAddr(lib, 'PyThreadState_Get');
  PyThreadState_Swap       := getProcAddr(lib, 'PyThreadState_Swap');
end;

var
  lib: TLibHandle;
initialization
  lib := loadLibrary(dllName);
  if lib <> NilLibHandle then init(lib);
end.
