discard """
nimout: '''
staticAlialProc instantiated with 358
staticAlialProc instantiated with 368
'''
output: '''
16
16
b is 2 times a
17
['\x00', '\x00', '\x00', '\x00']
'''
"""

import macros

template ok(x) = assert(x)
template no(x) = assert(not x)

template accept(x) =
  static: assert(compiles(x))

template reject(x) =
  static: assert(not compiles(x))

proc plus(a, b: int): int = a + b

template isStatic(x: static): bool = true
template isStatic(x: auto): bool = false

var v = 1

when true:
  # test that `isStatic` works as expected
  const C = 2

  static:
    ok C.isStatic
    ok isStatic(plus(1, 2))
    ok plus(C, 2).isStatic

    no isStatic(v)
    no plus(1, v).isStatic

when true:
  # test that proc instantiation works as expected
  type
    StaticTypeAlias = static[int]

  proc staticAliasProc(a: StaticTypeAlias,
                       b: static[int],
                       c: static int) =
    static:
      assert a.isStatic and b.isStatic and c.isStatic
      assert isStatic(a + plus(b, c))
      echo "staticAlialProc instantiated with ", a, b, c

    when b mod a == 0:
      echo "b is ", b div a, " times a"

    echo a + b + c

  staticAliasProc 1+2, 5, 8
  staticAliasProc 3, 2+3, 9-1
  staticAliasProc 3, 3+3, 4+4

when true:
  # test static coercions. normal cases that should work:
  accept:
    var s1 = static[int] plus(1, 2)
    var s2 = static(plus(1,2))
    var s3 = static plus(1,2)
    var s4 = static[SomeInteger](1 + 2)

  # the sub-script operator can be used only with types:
  reject:
    var just_static3 = static[plus(1,2)]

  # static coercion takes into account the type:
  reject:
    var x = static[string](plus(1, 2))
  reject:
    var x = static[string] plus(1, 2)
  reject:
    var x = static[SomeFloat] plus(3, 4)

  # you cannot coerce a run-time variable
  reject:
    var x = static(v)

block: # issue #13730
  type Foo[T: static[float]] = object
  doAssert Foo[0.0] is Foo[-0.0]

when true:
  type
    ArrayWrapper1[S: static int] = object
      data: array[S + 1, int]

    ArrayWrapper2[S: static[int]] = object
      data: array[S.plus(2), int]

    ArrayWrapper3[S: static[(int, string)]] = object
      data: array[S[0], int]

  var aw1: ArrayWrapper1[5]
  var aw2: ArrayWrapper2[5]
  var aw3: ArrayWrapper3[(10, "str")]

  static:
    assert aw1.data.high == 5
    assert aw2.data.high == 6
    assert aw3.data.high == 9

# #6077
block:
  type
    Backend = enum
      Cpu

    Tensor[B: static[Backend]; T] = object

    BackProp[B: static[Backend],T] = proc (gradient: Tensor[B,T]): Tensor[B,T]

# https://github.com/nim-lang/Nim/issues/10073
block:
  proc foo[N: static int](x: var int,
                          y: int,
                          z: static int,
                          arr: array[N, int]): auto =
    var t1 = (a: x, b: y, c: z, d: N)
    var t2 = (x, y, z, N)
    doAssert t1 == t2
    result = t1

  var y = 20
  var x = foo(y, 10, 15, [1, 2, 3])
  doAssert x == (20, 10, 15, 3)

# #7609
block:
  type
    Coord[N: static[int]] = tuple[col, row: range[0'i8 .. (N.int8-1)]]
    Point[N: static[int]] = range[0'i16 .. N.int16 * N.int16 - 1]

# https://github.com/nim-lang/Nim/issues/10339
block:
  type
    MicroKernel = object
      a: float
      b: int

  macro extractA(ukernel: static MicroKernel): untyped =
    result = newLit ukernel.a

  proc tFunc[ukernel: static MicroKernel]() =
    const x = ukernel.extractA
    doAssert x == 5.5

  const uk = MicroKernel(a: 5.5, b: 1)
  tFunc[uk]()


# bug #7258
type
  StringValue*[LEN: static[Natural]] = array[LEN+Natural(2),char]
  StringValue16* = StringValue[2]

var
  s: StringValue16

echo s
