type mytype* = object
  v:int

proc f*(x:ptr mytype) = x.v = -1

import x9578

func g(x:int):mytype = mytype(v:x)

var x = @[1.g,2.g,3.g]
testOpenArray(x)
echo x
