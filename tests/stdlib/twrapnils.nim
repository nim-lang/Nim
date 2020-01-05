import std/wrapnils

proc main() =
  type Bar = object
    b1: int
  type Foo = ref object
    x1: float
    x2: Foo
    x3: string
    x4: Bar
    x5: seq[int]

  var a: Foo
  var a2 = Foo(x1: 1.0, x5: @[10, 11])
  var a3 = Foo(x1: 1.2, x3: "abc")
  a3.x2 = a3

  var witness = 0
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

  # make sure no double evaluation bug
  doAssert witness == 0
  doAssert initFoo(1.3).wrapnil.x1[] == 1.3
  doAssert witness == 1

main()
