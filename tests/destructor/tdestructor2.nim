discard """
  line: 23
  nimout: " usage of a type with a destructor in a non destructible context"
"""

{.experimental.}

type  
  TMyObj = object
    x, y: int
    p: pointer
    
proc destroy(o: var TMyObj) {.override.} =
  if o.p != nil: dealloc o.p
  
proc open: TMyObj =
  result = TMyObj(x: 1, y: 2, p: alloc(3))


proc `$`(x: TMyObj): string = $x.y

proc foo =
  discard open()

# XXX doesn't trigger this yet:
#echo open()

