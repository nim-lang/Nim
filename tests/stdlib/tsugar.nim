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

# bug #7816
import sequtils

proc tester[T](x: T) =
  let test = toSeq(0..4).map(i => newSeq[int]())
  echo test

tester(1)
