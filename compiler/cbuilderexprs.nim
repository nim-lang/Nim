# XXX make these use builder instead

proc ptrType(t: Snippet): Snippet =
  t & "*"

proc bitOr(a, b: Snippet): Snippet =
  a & " | " & b
