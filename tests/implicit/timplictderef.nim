discard """
  output: "2"
"""

type
  TValue* {.pure, final.} = object of TObject
    a: int
  PValue = ref TValue
  PPValue = ptr PValue


var x: PValue
new x
var sp: PPValue = addr x

sp.a = 2
if sp.a == 2: echo 2  # with sp[].a the error is gone

