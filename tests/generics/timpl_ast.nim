import std/macros
import std/assertions

block: # issue #16639
  type Foo[T] = object
    when true:
      x: float

  type Bar = object
    when true:
      x: float

  macro test() =
    let a = getImpl(bindSym"Foo")[^1]
    let b = getImpl(bindSym"Bar")[^1]
    doAssert treeRepr(a) == treeRepr(b)

  test()

import strutils

block: # issues #9899, ##14708
  macro implRepr(a: typed): string =
    result = newLit(repr(a.getImpl))

  type
    Option[T] = object
      when false: discard # issue #14708
      when false: x: int
      when T is (ref | ptr):
        val: T
      else:
        val: T
        has: bool

  static: # check information is retained
    let r = implRepr(Option)
    doAssert "when T is" in r
    doAssert r.count("val: T") == 2
    doAssert "has: bool" in r

  block: # try to compile the output
    macro parse(s: static string) =
      result = parseStmt(s)
    parse("type " & implRepr(Option))

block: # issue #22639
  type
    Spectrum[N: static int] = object
      data: array[N, float]
    AngleInterpolator = object
      data: seq[Spectrum[60]]
  proc initInterpolator(num: int): AngleInterpolator =
    result = AngleInterpolator()
    for i in 0 ..< num:
      result.data.add Spectrum[60]()
  macro genCompatibleTuple(t: typed): untyped =
    let typ = t.getType[1].getTypeImpl[2]
    result = nnkTupleTy.newTree()
    for i, ch in typ: # is `nnkObjectTy`
      result.add nnkIdentDefs.newTree(ident(ch[0].strVal), # ch is `nnkIdentDefs`
                                      ch[1],
                                      newEmptyNode())
  proc fullSize[T: object | tuple](x: T): int =
    var tmp: genCompatibleTuple(T)
    result = 0
    for field, val in fieldPairs(x):
      result += sizeof(val)
    doAssert result == sizeof(tmp)

  let reflectivity = initInterpolator(1)
  for el in reflectivity.data:
    doAssert fullSize(el) == sizeof(el)
  doAssert fullSize(reflectivity.data[0]) == sizeof(reflectivity.data[0])
  doAssert genCompatibleTuple(Spectrum[60]) is tuple[data: array[60, float]]
  doAssert genCompatibleTuple(Spectrum[120]) is tuple[data: array[120, float]]
  type Foo[T] = object
    data: T
  doAssert genCompatibleTuple(Foo[int]) is tuple[data: int]
  doAssert genCompatibleTuple(Foo[float]) is tuple[data: float]
