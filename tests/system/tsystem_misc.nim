discard """
  targets: "c cpp js"
"""

# xxx simplify pending https://github.com/nim-lang/RFCs/issues/283
# for testing against template double evaluation bugs
var witnessRT = 0
var witnessCT {.compileTime.} = 0
proc witness(): int =
  when nimvm: witnessCT
  else: witnessRT
proc identity[T](a: var T): var T =
  when nimvm: witnessCT.inc
  else: witnessRT.inc
  a

block:
  const a2 = $(int)
  const a3 = $int
  doAssert a2 == "int"
  doAssert a3 == "int"

  proc fun[T: typedesc](t: T) =
    const a2 = $(t)
    const a3 = $t
    doAssert a2 == "int"
    doAssert a3 == "int"
  fun(int)

# check high/low implementations
doAssert high(int) > low(int)
doAssert high(int8) > low(int8)
doAssert high(int16) > low(int16)
doAssert high(int32) > low(int32)
doAssert high(int64) > low(int64)
# doAssert high(uint) > low(uint) # reconsider depending on issue #6620
doAssert high(uint8) > low(uint8)
doAssert high(uint16) > low(uint16)
doAssert high(uint32) > low(uint32)
# doAssert high(uint64) > low(uint64) # reconsider depending on issue #6620
doAssert high(float) > low(float)
doAssert high(float32) > low(float32)
doAssert high(float64) > low(float64)

# bug #6710
var s = @[1]
s.delete(0)


proc foo(a: openArray[int]): seq[int] =
  for x in a: result.add x

doAssert foo(toOpenArray([1, 2, 3], 0, 0)) == @[1]
doAssert foo(toOpenArray([1, 2, 3], 0, 2)) == @[1, 2, 3]
var arr: array[8..12, int] = [11, 12, 13, 14, 15]

when not defined js:
  doAssert foo(toOpenArray(arr, 8, 12)) == @[11, 12, 13, 14, 15]

var seqq = @[1, 2, 3, 4, 5]
doAssert foo(toOpenArray(seqq, 1, 3)) == @[2, 3, 4]

# empty openArray issue #7904
doAssert foo(toOpenArray(seqq, 0, -1)) == @[]
doAssert foo(toOpenArray(seqq, 1, 0)) == @[]

when not defined js: # xxx
  doAssertRaises(IndexDefect):
    discard foo(toOpenArray(seqq, 0, -2))
  doAssertRaises(IndexDefect):
    discard foo(toOpenArray(arr, 10, 8))

doAssert foo(toOpenArray(arr, 9, 8)) == @[]
doAssert foo(toOpenArray(arr, 0, -1)) == @[]
doAssert foo(toOpenArray(arr, 1, 0)) == @[]

# test openArray of openArray
proc oaEmpty(a: openArray[int]): auto =
  foo(toOpenArray(a, 0, -1))

proc oaFirstElm(a: openArray[int]): auto =
  foo(toOpenArray(a, 0, 0))

doAssert oaEmpty(toOpenArray(seqq, 0, -1)) == @[]
doAssert oaEmpty(toOpenArray(seqq, 1, 0)) == @[]
doAssert oaEmpty(toOpenArray(seqq, 1, 2)) == @[]
doAssert oaFirstElm(toOpenArray(seqq, 1, seqq.len-1)) == @[2]

var arrNeg: array[-3 .. -1, int] = [1, 2, 3]

when not defined js:
  doAssert foo(toOpenArray(arrNeg, -3, -1)) == @[1, 2, 3]

doAssert foo(toOpenArray(arrNeg, 0, -1)) == @[]
doAssert foo(toOpenArray(arrNeg, -3, -4)) == @[]

doAssertRaises(Exception):
  raise newException(Exception, "foo")

when not defined js: # xxx
  doAssertRaises(IndexDefect):
    discard foo(toOpenArray(arrNeg, -4, -1))
  doAssertRaises(IndexDefect):
    discard foo(toOpenArray(arrNeg, -1, 0))
  doAssertRaises(IndexDefect):
    discard foo(toOpenArray(arrNeg, -1, -3))

block:
  var didThrow = false
  try:
    doAssertRaises(IndexDefect): # should fail since it's wrong exception
      raise newException(FieldDefect, "foo")
  except AssertionDefect:
    # ok, throwing was correct behavior
    didThrow = true
  doAssert didThrow

block:
  type seqqType = ptr UncheckedArray[int]
  let qData = cast[seqqType](addr seqq[0])
  when not defined js: # xxx
    doAssert oaFirstElm(toOpenArray(qData, 1, 3)) == @[2]

block:
  proc foo(a: openArray[byte]): seq[int] =
    for x in a: result.add x.int

  let str = "0123456789"
  doAssert foo(toOpenArrayByte(str, 0, str.high)) == @[48, 49, 50, 51, 52, 53, 54, 55, 56, 57]

block:
  template boundedOpenArray[T](x: seq[T], first, last: int): openarray[T] =
    toOpenarray(x, max(0, first), min(x.high, last))

  # bug #9281
  proc foo[T](x: openarray[T]): int =
    x.len

  let a = @[1, 2, 3]

  doAssert a.boundedOpenArray(1, 2).len == 2 # was: Internal compiler error
  doAssert a.boundedOpenArray(1, 2).foo() == @[2, 3]

when false:
  block: # `$`*[T: tuple|object](x: T)
    doAssert $(foo1:0, bar1:"a") == """(foo1: 0, bar1: "a")"""
    doAssert $(foo1:0, ) == """(foo1: 0)"""
    doAssert $(0, "a") == """(0, "a")"""
    doAssert $(0, ) == "(0,)"
    type Foo = object
      x:int
      x2:float
    doAssert $Foo(x:2) == "(x: 2, x2: 0.0)"
    doAssert $() == "()"

  # this is a call indirection to prevent `toInt` to be resolved at compile time.
  proc testToInt(arg: float64, a: int, b: BiggestInt) =
    doAssert toInt(arg) == a
    when not defined js: # xxx
      doAssert toBiggestInt(arg) == b

  testToInt(0.45, 0, 0)    # should round towards 0
  testToInt(-0.45, 0, 0)   # should round towards 0
  testToInt(0.5, 1, 1)     # should round away from 0
  testToInt(-0.5, -1, -1)  # should round away from 0
  testToInt(13.37, 13, 13)    # should round towards 0
  testToInt(-13.37, -13, -13) # should round towards 0
  testToInt(7.8, 8, 8)     # should round away from 0
  testToInt(-7.8, -8, -8)  # should round away from 0

  # test min/max for correct NaN handling

  proc testMinMax(a,b: float32) =
    doAssert max(float32(a),float32(b)) == 0'f32
    doAssert min(float32(a),float32(b)) == 0'f32
    doAssert max(float64(a),float64(b)) == 0'f64
    doAssert min(float64(a),float64(b)) == 0'f64

  testMinMax(0.0, NaN)
  testMinMax(NaN, 0.0)


  block:
    type Foo = enum
      k1, k2
    var
      a = {k1}
      b = {k1,k2}
    doAssert a < b


  block: # Ordinal
    doAssert int is Ordinal
    doAssert uint is Ordinal
    doAssert int64 is Ordinal
    doAssert uint64 is Ordinal
    doAssert char is Ordinal
    type Foo = enum k1, k2
    doAssert Foo is Ordinal
    doAssert Foo is SomeOrdinal
    doAssert enum is SomeOrdinal

    # these fail:
    # doAssert enum is Ordinal # fails
    # doAssert Ordinal is SomeOrdinal
    # doAssert SomeOrdinal is Ordinal

  block:
    proc p() = discard

    doAssert not compiles(echo p.rawProc.repr)
    doAssert not compiles(echo p.rawEnv.repr)
    doAssert not compiles(echo p.finished)

template main() =
  #[
  xxx test VM by wrapping in the usual pattern: main(); static main()
      improve test organization further using `block: # funName`
  ]#
  block: # swap
    block: # bug #16771
      type A = object
        n: int
      var a = A(n: 1)
      var b = A(n: 2)
      a.swap b
      doAssert (a.n, b.n) == (2, 1)
      proc foo(a, b: var A) = swap a, b
      a.foo b
      doAssert (a.n, b.n) == (1, 2)

    block: # bug #16779
      var
        c1 = 1
        c2 = 2
      doAssert witness() == 0
      swap(identity(c1), identity(c2))
      doAssert (c1, c2) == (2, 1)
      when nimvm: # xxx bug still present in vm
        discard
      else:
        doAssert witness() == 2, $witness()

main()
static: main()
