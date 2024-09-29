discard """
  disabled: true
"""

# test that static conversions work

block: # issue #12559
  type T = ref object
    x: int
  proc f(arg: static T) =
    static:
      assert arg == nil or arg.x > 0
    discard arg.x
  f nil

block: # issue #16969
  proc foo(n: static[1..50]) = discard

  foo(1)
  doAssert not compiles(foo(0))
  doAssert not compiles(foo(999))

block: # issue #7611
  type Foo[N: static[int8]] = object

  proc `$`[N: static[int8]](f: Foo[N]): string =
    "Success"

  let a = Foo[10]()
  doAssert $a == "Success"

block: # issue #17423
  type NaturalArray[N: static[Natural]] = array[N, int]

  doAssert not (compiles do:
    var a: NaturalArray[-1000])

block: # test from https://github.com/nim-works/nimskull/pull/1433
  proc foo(x: static pointer): pointer = x
  proc foo(x: static array[0, int]): array[0, int] = x
  proc foo(x: static seq[int]): seq[int] = x
  proc foo(x: static set[char]): set[char] = x

  # simple case: empty-container typed expression is passed directly
  doAssert foo(nil) == nil
  doAssert foo([]) == []
  doAssert foo(@[]) == @[]
  doAssert foo({}) == {}

block: # generic version
  proc foo[T](x: static[ptr T]): ptr T = x
  proc foo[T](x: static array[0, T]): array[0, T] = x
  proc foo[T](x: static seq[T]): seq[T] = x
  proc foo[T](x: static set[T]): set[T] = x
  doAssert foo[int8](nil) == nil
  doAssert foo[int8]([]) == []
  doAssert foo[int8](@[]) == @[]
  doAssert foo[int8]({}) == {}

converter toInt(x: float): int = int(x)
block: # converter
  proc test(x: static int) =
    doAssert x == 1
  test(1.5)

block: # subtype
  type
    A = ref object of RootObj
    B = ref object of A

  proc test(x: static A) = discard
  test(B())

# proc explicit generic params don't work yet because typeRel doesn't use paramTypesMatch, #23343
