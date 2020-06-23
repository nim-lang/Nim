#[
D20190811T003919
]#

import std/lambdas
import ./mlambda except elementType

{.push experimental:"alias".}

const elementType = alias2 mlambda.elementType

proc toSeq[T](a: T): auto =
  type T = elementType(a)
  result = newSeq[T]()
  for x in a: result.add x

iterator iota(n: int): auto =
  for i in 0..<n: yield i

iterator iota3(): auto =
  for i in 0..<3: yield i

iterator filter[T, T2](a: T, cond: T2): auto =
  for ai in a:
    if cond(ai): yield ai

iterator map[T, T2](a: T, fun: T2): auto =
  for ai in a: yield fun(ai)

iterator join[T1, T2](a: T1, b: T2): auto =
  for x in a: yield x
  for x in b: yield x

proc testIterator*() =
  ## with an inline iterator
  block:
    iterator tfun6[T](a: T): auto =
      for ai in a:
        yield ai*2

    const tfun6a = alias2 tfun6
    var s: seq[int]
    for ai in tfun6a([1,2,3]): s.add ai # explicit iteration
    doAssert s == @[2,4,6]
    doAssert toSeq([1,2,3]) == @[1,2,3]
    doAssert toSeq(lambdaIter tfun6a(@[1,2,3])) == @[2,4,6]

  block:
    doAssert toSeq(lambdaIter iota(3)) == @[0,1,2]
    doAssert toSeq(lambdaIter iota3()) == @[0,1,2]
    doAssert toSeq(lambdaIter filter([1,2,3,4], a~>a mod 2 == 0)) == @[2, 4]
    doAssert toSeq(lambdaIter filter(lambdaIter iota(6), a~>a mod 2 == 0)) == @[0, 2, 4]
    doAssert toSeq(lambdaIter map(lambdaIter iota(3), a~>a*10)) == @[0, 10, 20]

    ## iterator composition; note that it's all lazy until toSeq is called
    const a0 =  lambdaIter map(lambdaIter iota(10), a ~> a * 2)
    doAssert toSeq(lambdaIter a0()) == @[0, 2, 4, 6, 8, 10, 12, 14, 16, 18]
    const a1 =  lambdaIter filter(lambdaIter a0(), a ~> a < 6)
    doAssert toSeq(lambdaIter a1()) == @[0, 2, 4]
    const a3 = lambdaIter join(lambdaIter iota(3), lambdaIter iota(2))
    doAssert toSeq(lambdaIter a3) == @[0, 1, 2, 0, 1]

proc testIssue4516*() = # solution for https://github.com/nim-lang/Nim/issues/4516
  # iterator test2(it: iterator(): int {.inline.}): int = # would not work without aliassym
  iterator test2(it: aliassym): int =
    for i in it():
      yield i*2

  iterator test1(): int =
    yield 10
    yield 20
    yield 30

  var s: seq[int]
  for i in test2(lambdaIter test1()):
    s.add i
  doAssert s == @[20, 40, 60]

proc testIterator2*() =
  iterator iterAux(a: aliassym): auto =
    for x in a: yield x

  proc iterAux3(a: aliassym): aliassym =
    iterator bar(): int {.inline.} =
      for x in a: yield x
    lambdaIter bar()

  proc iterAux4(a: aliassym): aliassym =
    iterator bar(): int {.inline.} =
      for x in a: yield x*10
    alias2 bar

  proc iterAux5[T1, T2](a: T1, b: T2): aliassym =
    iterator bar(): auto {.inline.} =
      for x in a: yield x
      for x in b: yield x
    lambdaIter bar()

  iterator iterAux6(a, b: aliassym): auto {.inline.} =# doesn't work
    for x in a: yield x
    for x in b: yield x

  iterator myiter[T](a: T): auto =
    for x in a: yield x

  doAssert elementType(iota3()) is int
  const myiter2a = alias2 iota3
  block:
    var ret: seq[int]
    for ai in myiter2a(): ret.add ai
    doAssert ret == @[0,1,2]

  block:
    const myiter2b = lambdaIter iota3()
    doAssert type(myiter2b) is int
    doAssert toSeq(lambdaIter iota3()) == @[0, 1, 2]
    doAssert toSeq(lambdaIter iota3()) == @[0, 1, 2]
    doAssert toSeq(lambdaIter iota3Bis()) == @[0, 1, 2] # import test
    doAssert toSeq(lambdaIter myiter2b) == @[0, 1, 2]
    # make sure restarts from beginning
    doAssert toSeq(lambdaIter myiter2b) == @[0,1,2]
    doAssert toSeq(@[2,3,4]) == @[2,3,4]

  let s0 = default(elementType(myiter2a()))
  doAssert toSeq(lambdaIter iota3()) == @[0, 1, 2]

  block:
    const i1 = lambdaIter iota3()
    doAssert type(i1) is int
    doAssert typeof(i1) is int
    doAssert toSeq(alias2 i1) == @[0, 1, 2]

    const i2 = lambdaIter iterAux(lambdaIter iota3())
    doAssert type(i2) is int
    doAssert typeof(i2) is int

    block: # D20190818T125934:here D20190816T205304:here
      const i3 = alias2 iterAux4(lambdaIter iota3())
      static: doAssert type(i3) is iterator
      static: doAssert typeof(i3) is iterator
      static: doAssert type(i3()) is int
      var ret: seq[int]
      for ai in i3(): ret.add ai
      doAssert ret == @[0, 10, 20]

    block:
      const i3 = lambdaIter iterAux4(lambdaIter iota3())()
      static: doAssert type(i3) is int
      static: doAssert type(i3()) is int
      static: doAssert typeof(i3) is int
      doAssert toSeq(alias2 i3) == @[0, 10, 20]

    block:
      const i5 = alias2 iterAux5(lambdaIter iota3(), lambdaIter iota3())
      doAssert toSeq(alias2 i5) == @[0, 1, 2, 0, 1, 2]

proc testArrowWrongSym2() =
  # similar to `testArrowWrongSym`
  template a(): untyped = discard # distractor
  template c(): untyped = discard # distractor
  doAssert toSeq(lambdaIter map(lambdaIter map(lambdaIter iota(3), a~>a*10), c~>c*4)) == @[0, 1*10*4, 2*10*4]

proc testAll*() =
  testIterator()
  testIterator2()
  testIssue4516()
  testArrowWrongSym2()

testAll()

{.pop.}
