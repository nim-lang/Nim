# XXX make complex ones like bitOr use builder instead

proc ptrType(t: Snippet): Snippet =
  t & "*"

proc procPtrType(conv: TCallingConvention, rettype: Snippet, name: string): Snippet =
  CallingConvToStr[t.callConv] & "_PTR(" & rettype & ", " & name & ")"

proc bitOr(a, b: Snippet): Snippet =
  a & " | " & b
