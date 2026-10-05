discard """
  targets: "c cpp"
  matrix: "-d:checkAbi"
"""

# bug #26220: `array[0, T]` is emitted as `T[1]` in C, the size computed
# by Nim has to agree, otherwise the ABI check fails.

type
  Future[T] = ref object of RootObj
    a: int8
    when T isnot void:
      v: T
  RaisesFuture[T, E] = ref object of Future[T]
    when E is void:
      dummy: E
    else:
      dummy: array[0, E]

  Obj = object
    a: int32
    b: array[0, int8]

let x = RaisesFuture[void, (ValueError, OSError)]()
let y = RaisesFuture[int8, int8]()
var o = Obj(a: 1)
doAssert x != nil and y != nil and o.a == 1
doAssert sizeof(Obj) == 8
