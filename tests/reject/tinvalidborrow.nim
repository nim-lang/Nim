discard """
  line: 11
  errormsg: "no symbol to borrow from found"
"""

# bug #516

type
  TAtom = culong

proc `==`*(a, b: TAtom): bool {.borrow.}

var
  d, e: TAtom

echo( $(d == e) )

