# Make sure we don't walk cast[T] type section while injecting sinks/destructors
block:
  type
    XY[T] = object
      discard

  proc `=`[T](x: var XY[T]; v: XY[T]) {.error.}
  proc `=sink`[T](x: var XY[T]; v: XY[T]) {.error.}

  proc main[T]() =
    var m = cast[ptr XY[T]](alloc0(sizeof(XY[T])))
    doAssert(m != nil)

  main[int]()
