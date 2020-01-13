import sugar
import macros

block byRefBlock:
  var count = 0
  proc identity(a: int): auto =
    block: count.inc; a
  var x = @[1,2,3]
  byRef: x1=x[identity(1)] # the lvalue expression is evaluated only here
  doAssert count == 1
  x1 += 10
  doAssert type(x1) is int # use x1 just like a normal variable
  doAssert x == @[1,12,3]
  doAssert count == 1 # count has not changed
  doAssert compiles (block: byRef: x2=x[0])
  doAssert not compiles (block: byRef: x2=y[0])
    # correctly does not compile when using invalid lvalue expression

block byPtrfBlock:
  type Foo = object
    x: string
  proc fun(a: Foo): auto =
    doAssert not compiles (block: byRef: x=a.x)
  let foo = Foo(x: "asdf")
  fun(foo)

# test byRef with export
import ./msugar
barx += 10
doAssert $foo == "(bar: (x: 10))"

# bug #7816
import sequtils

proc tester[T](x: T) =
  let test = toSeq(0..4).map(i => newSeq[int]())
  doAssert $test == """@[@[], @[], @[], @[], @[]]"""

tester(1)
