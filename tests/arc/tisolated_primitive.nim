# Issue: genMagicExpr: mAsgn internal error when using Isolated[T] with primitive types
# in tuple assignment to pointer dereference

import std/isolation

proc main() =
  var x: ptr Isolated[float]
  x = cast[ptr Isolated[float]](alloc0(sizeof(Isolated[float])))
  x[] = isolate(42.0)
  dealloc(x)

main()
