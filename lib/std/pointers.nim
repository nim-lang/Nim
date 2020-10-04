##[
Convenience procs to process `ptr[T]` variables without requiring `cast`.
]##

runnableExamples:
  var a = @[10, 11, 12]
  let pa = a[0].addr
  doAssert (pa + 1)[] == 11
  doAssert pa[2] == 12
  pa[1] = 2
  doAssert a[1] == 2


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

proc `+=`*[T](p: var ptr T, off: int) {.inline.} =
  # not a template to avoid double evaluation issues
  p = p + off

proc `-=`*[T](p: var ptr T, off: int) {.inline.} =
  p = p - off
