discard """
  file: "tsugar.nim"
  output: ""
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

block extractGeneric:
  type Foo[T1, T2]=object
  type Foo2=Foo[float, string]
  doAssert extractGeneric(Foo[float, string], 1) is string
  doAssert extractGeneric(Foo2, 1) is string
  # workaround for seq[int].T not working,
  # see https://github.com/nim-lang/Nim/issues/8433
  doAssert extractGeneric(seq[int], 0) is int
  doAssert extractGeneric(seq[seq[string]], 0) is seq[string]
  doAssert: not compiles(extractGeneric(seq[int], 1))
  doAssert extractGeneric(seq[int], -1) is seq

  type Foo3[T] = T
  doAssert extractGeneric(Foo3[int], 0) is int
