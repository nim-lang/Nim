discard """
cmd: "nim check $file"
action: "compile"
errormsg: "type mismatch: got <Subclass[system.int]>"
line: 21
"""

{.experimental: "strictDefs".}

type
  Superclass[T] = object of RootObj
    a: T
  Subclass[T] = object of Superclass[T]
    s: string

proc init[T](x: out Superclass[T]) =
  x = Superclass(a: 8)

proc subtypeCheck =
  var v: Subclass[int]
  init(v)
  echo v.s # the 's' field was never initialized!

subtypeCheck()
