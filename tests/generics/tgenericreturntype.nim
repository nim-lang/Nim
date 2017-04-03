discard """
  output: "(fooInt: 13)"
"""

type Foo = object
  fooInt*: int
  
proc createX(T: typedesc): ptr T =
  createU(T)
  
var f = createX(Foo)
f.fooInt = 13
echo f[]

  
  