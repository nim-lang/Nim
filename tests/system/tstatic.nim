discard """
  targets: "c cpp js"
"""

import std/strutils

# bug #6133
template main() =
  block:
    block:
      proc foo(q: string, a: int): int =
        result = q.len

      proc foo(q: static[string]): int =
        result = foo(q, 5)

      doAssert foo("123") == 3

    block:
      type E = enum A

      if false:
        var e = A
        discard $e

      proc foo(a: string): int =
        len(a) # 16640

      proc foo(a: static[bool]): int {.used.} =
        discard

      doAssert foo("") == 0

    block:
      proc foo(a: string): int =
        len(a)

      proc foo(a: static[bool]): int {.used.} =
        discard

      doAssert foo("abc") == 3

    block:
      proc parseInt(f: static[bool]): int {.used.} = discard

      doAssert "123".parseInt == 123
  block:
    type
      MyType = object
        field: float32
      AType[T: static MyType] = distinct range[0f32 .. T.field]
    var a: AType[MyType(field: 5f32)]
    proc n(S: static Slice[int]): range[S.a..S.b] = discard
    assert typeof(n 1..2) is range[1..2]


static: main()
main()
