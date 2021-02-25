import std/wrapnils

proc checkNotZero(x: float): float =
  doAssert x != 0
  x

proc main() =
  var witness = 0
  type Bar = object
    b1: int
    b2: ptr string

  type Foo = ref object
    x1: float
    x2: Foo
    x3: string
    x4: Bar
    x5: seq[int]
    x6: ptr Bar
    x7: array[2, string]
    x8: seq[int]
    x9: ref Bar

  type Gook = ref object
    foo: Foo

  proc fun(a: Bar): auto = a.b2

  var a: Foo

  var x6: ptr Bar
  when nimvm: discard # pending https://github.com/timotheecour/Nim/issues/568
  else:
    x6 = create(Bar)
    x6.b1 = 42
  var a2 = Foo(x1: 1.0, x5: @[10, 11], x6: x6)
  var a3 = Foo(x1: 1.2, x3: "abc")
  a3.x2 = a3

  var gook = Gook(foo: a)

  proc initFoo(x1: float): auto =
    witness.inc
    result = Foo(x1: x1)

  doAssert ?.a.x2.x2.x1 == 0.0
  doAssert ?.a3.x2.x2.x1 == 1.2
  doAssert ?.a3.x2.x2.x3[1] == 'b'

  doAssert ?.a3.x2.x2.x5.len == 0
  doAssert a3.x2.x2.x3.len == 3

  doAssert ?.a.x2.x2.x3[1] == default(char)
  # here we only apply wrapnil around gook.foo, not gook (and assume gook is not nil)
  doAssert ?.(gook.foo).x2.x2.x1 == 0.0

  when nimvm: discard
  else:
    doAssert ?.a2.x6[] == Bar(b1: 42) # deref for ptr Bar

  doAssert ?.a2.x1.checkNotZero == 1.0
  doAssert a == nil
  # shows that checkNotZero won't be called if a nil is found earlier in chain
  doAssert ?.a.x1.checkNotZero == 0.0

  when nimvm: discard
  else:
    # checks that a chain without nil but with an empty seq still raises
    doAssertRaises(IndexDefect): discard ?.a2.x8[3]

  # make sure no double evaluation bug
  doAssert witness == 0
  doAssert ?.initFoo(1.3).x1 == 1.3
  doAssert witness == 1

  # here, it's used twice, to deref `ref Bar` and then `ptr string`
  doAssert ?.a.x9[].fun[] == ""

  block: # `??.`
    doAssert (??.a3.x2.x2.x3.len).get == 3
    doAssert (??.a2.x4).isSome
    doAssert not (??.a.x4).isSome

main()
static: main()
