discard """
  errormsg: "type mismatch: got <TKind>"
  file: "tadrdisc.nim"
  line: 20
"""
# Test that the address of a discriminants cannot be taken

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
