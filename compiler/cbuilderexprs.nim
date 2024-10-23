# XXX make complex ones like bitOr use builder instead
# XXX add stuff like NI, NIM_NIL as constants

proc ptrType(t: Snippet): Snippet =
  t & "*"

const
  CallingConvToStr: array[TCallingConvention, string] = ["N_NIMCALL",
    "N_STDCALL", "N_CDECL", "N_SAFECALL",
    "N_SYSCALL", # this is probably not correct for all platforms,
                 # but one can #define it to what one wants
    "N_INLINE", "N_NOINLINE", "N_FASTCALL", "N_THISCALL", "N_CLOSURE", "N_NOCONV",
    "N_NOCONV" #ccMember is N_NOCONV
    ]

proc procPtrType(conv: TCallingConvention, rettype: Snippet, name: string): Snippet =
  CallingConvToStr[conv] & "_PTR(" & rettype & ", " & name & ")"

proc cCast(typ, value: Snippet): Snippet =
  "((" & typ & ") " & value & ")"

proc wrapPar(value: Snippet): Snippet =
  # used for expression group, no-op on sexp
  "(" & value & ")"

template addCast(builder: var Builder, typ: Snippet, valueBody: typed) =
  ## adds a cast to `typ` with value built by `valueBody`
  builder.add "(("
  builder.add typ
  builder.add ") "
  valueBody
  builder.add ")"

proc cAddr(value: Snippet): Snippet =
  "&" & value

proc cDeref(value: Snippet): Snippet =
  "(*" & value & ")"

proc subscript(a, b: Snippet): Snippet =
  a & "[" & b & "]"

proc dotField(a, b: Snippet): Snippet =
  a & "." & b

proc derefField(a, b: Snippet): Snippet =
  a & "->" & b

proc bitOr(a, b: Snippet): Snippet =
  "(" & a & " | " & b & ")"
