import std/wrapnils


proc checkNotZero(x: float): float =
  doAssert x != 0
  x

var witness = 0

proc main() =
  type Bar = object
    b1: int
  type Foo = ref object
    x1: float
    x2: Foo
    x3: string
    x4: Bar
    x5: seq[int]
    x6: ptr Bar
    x7: array[2, string]
    x8: seq[int]

  var a: Foo
  var x6 = create(Bar)
  x6.b1 = 42
  var a2 = Foo(x1: 1.0, x5: @[10, 11], x6: x6)
  var a3 = Foo(x1: 1.2, x3: "abc")
  a3.x2 = a3

  proc initFoo(x1: float): auto =
    witness.inc
    result = Foo(x1: x1)

  doAssert a.wrapnil.x2.x2.x1[] == 0.0
  doAssert a3.wrapnil.x2.x2.x1[] == 1.2
  doAssert a3.wrapnil.x2.x2.x5.len[] == 0
  doAssert a3.wrapnil.x2.x2.x3.len[] == 3
  doAssert a3.wrapnil.x2.x2.x3.len == wrapnil(3)
  doAssert a3.wrapnil.x2.x2.x3[1][] == 'b'
  doAssert a.wrapnil.x2.x2.x3[1][] == default(char)

  doAssert a2.wrapnil.x6[][] == Bar(b1: 42) # 2nd deref for ptr Bar

  doAssert a2.wrapnil.x1.checkNotZero[] == 1.0
  doAssert a == nil
  # shows that checkNotZero won't be called if a nil is found earlier in chain
  doAssert a.wrapnil.x1.checkNotZero[] == 0.0

  doAssert a2.wrapnil.x4.isNotNil
  doAssert not a.wrapnil.x4.isNotNil

  # checks that a chain without nil but with an empty seq still throws IndexError
  doAssertRaises(IndexError): discard a2.wrapnil.x8[3]

  # make sure no double evaluation bug
  doAssert witness == 0
  doAssert initFoo(1.3).wrapnil.x1[] == 1.3
  doAssert witness == 1

main()
