discard """
  errormsg: "undeclared identifier: \'b\'"
  file: "ttempl2.nim"
  line: 18
"""
template declareInScope(x: untyped, t: typeDesc): untyped =
  var x: t

template declareInNewScope(x: untyped, t: typeDesc): untyped =
  # open a new scope:
  block:
    var x: t

declareInScope(a, int)
a = 42  # works, `a` is known here

declareInNewScope(b, int)
b = 42  #ERROR_MSG undeclared identifier: 'b'
