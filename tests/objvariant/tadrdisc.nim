discard """
  file: "tadrdisc.nim"
  line: 20
  errormsg: "type mismatch: got <TKind>"
"""
# Test that the address of a dicriminants cannot be taken

type
  TKind = enum ka, kb, kc
  TA = object
    case k: TKind
    of ka: x, y: int
    of kb: a, b: string
    of kc: c, d: float

proc setKind(k: var TKind) =
  k = kc

var a: TA
setKind(a.k)
