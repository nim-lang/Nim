# bug #12559: the field of a `static` nil ref
type T = ref object
  x: int

proc foo(arg: static T): int =
  static:
    assert arg == nil or arg.x > 0
  result = (if arg == nil: -1 else: arg.x)

doAssert foo(nil) == -1
doAssert foo(T(x: 3)) == 3
