discard """
  line: 20
  errormsg: " usage of a type with a destructor in a non destructible context"
"""

type  
  TMyObj = object
    x, y: int
    p: pointer
    
proc destruct(o: var TMyObj) {.destructor.} =
  if o.p != nil: dealloc o.p
  
proc open: TMyObj =
  result = TMyObj(x: 1, y: 2, p: alloc(3))


proc `$`(x: TMyObj): string = $x.y

echo open()

