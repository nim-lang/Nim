# XXX make complex ones like bitOr use builder instead

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

proc cAddr(value: Snippet): Snippet =
  "&" & value

proc bitOr(a, b: Snippet): Snippet =
  "(" & a & " | " & b & ")"
