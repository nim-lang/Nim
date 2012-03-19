discard """
  file: "ttempl2.nim"
  line: 18
  errormsg: "undeclared identifier: \'b\'"
"""
template declareInScope(x: expr, t: typeDesc): stmt {.immediate.} =
  var x: t
  
template declareInNewScope(x: expr, t: typeDesc): stmt {.immediate.} =
  # open a new scope:
  block: 
    var x: t

declareInScope(a, int)
a = 42  # works, `a` is known here

declareInNewScope(b, int)
b = 42  #ERROR_MSG undeclared identifier: 'b'

