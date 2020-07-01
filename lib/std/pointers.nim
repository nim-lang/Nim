template `+`*[T](p: ptr T, off: int): ptr T =
  type T = typeof(p[]) # pending https://github.com/nim-lang/Nim/issues/13527
  cast[ptr T](cast[ByteAddress](p) +% off * sizeof(T))

template `-`*[T](p: ptr T, off: int): ptr T =
  type T = typeof(p[])
  cast[ptr T](cast[ByteAddress](p) -% off * sizeof(T))

template `[]`*[T](p: ptr T, off: int): T =
  (p + off)[]

template `[]=`*[T](p: ptr T, off: int, val: T) =
  (p + off)[] = val

proc `+=`*[T](p: ptr T, off: int) {.inline.} =
  # not a template to avoid double evaluation issues
  p = p + off

proc `-=`*[T](p: ptr T, off: int) {.inline.} =
  p = p - off
