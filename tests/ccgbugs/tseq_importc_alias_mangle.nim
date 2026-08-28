discard """
  action: run
  targets: "c cpp"
"""

type CIntAlias = cint

var x: (cint,) = (1.cint,)
var y: (CIntAlias,) = x
x = y
doAssert x[0] == 1.cint

var a: seq[cint]
var b: seq[CIntAlias]
a.add 1.cint
a.add 2.cint
b = a
a = b
doAssert a[0] == 1.cint
doAssert b[1] == CIntAlias(2)
