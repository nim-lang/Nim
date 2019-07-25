discard """
  output: "@[@[], @[], @[], @[], @[]]"
"""
import sugar
import macros

block distinctBase:
  block:
    type
      Foo[T] = distinct seq[T]
    var a: Foo[int]
    doAssert a.type.distinctBase is seq[int]

  block:
    # simplified from https://github.com/nim-lang/Nim/pull/8531#issuecomment-410436458
    macro uintImpl(bits: static[int]): untyped =
      if bits >= 128:
        let inner = getAST(uintImpl(bits div 2))
        result = newTree(nnkBracketExpr, ident("UintImpl"), inner)
      else:
        result = ident("uint64")

    type
      BaseUint = UintImpl or SomeUnsignedInt
      UintImpl[Baseuint] = object
      Uint[bits: static[int]] = distinct uintImpl(bits)

    doAssert Uint[128].distinctBase is UintImpl[uint64]

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
    byPtr: x=a.x
    x[0]='X'
  let foo = Foo(x: "asdf")
  fun(foo)
  doAssert foo.x == "Xsdf"

# bug #7816
import sequtils

proc tester[T](x: T) =
  let test = toSeq(0..4).map(i => newSeq[int]())
  echo test

tester(1)
