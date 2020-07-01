import std/sequtils
import strutils
from algorithm import sorted

# helper for testing double substitution side effects which are handled
# by `evalOnceAs`
var counter = 0
proc identity[T](a: T): auto =
  counter.inc
  a

block: # concat test
  let
    s1 = @[1, 2, 3]
    s2 = @[4, 5]
    s3 = @[6, 7]
    total = concat(s1, s2, s3)
  assert total == @[1, 2, 3, 4, 5, 6, 7]

block: # count test
  let
    s1 = @[1, 2, 3, 2]
    s2 = @['a', 'b', 'x', 'a']
    a1 = [1, 2, 3, 2]
    a2 = ['a', 'b', 'x', 'a']
    r0 = count(s1, 0)
    r1 = count(s1, 1)
    r2 = count(s1, 2)
    r3 = count(s2, 'y')
    r4 = count(s2, 'x')
    r5 = count(s2, 'a')
    ar0 = count(a1, 0)
    ar1 = count(a1, 1)
    ar2 = count(a1, 2)
    ar3 = count(a2, 'y')
    ar4 = count(a2, 'x')
    ar5 = count(a2, 'a')
  assert r0 == 0
  assert r1 == 1
  assert r2 == 2
  assert r3 == 0
  assert r4 == 1
  assert r5 == 2
  assert ar0 == 0
  assert ar1 == 1
  assert ar2 == 2
  assert ar3 == 0
  assert ar4 == 1
  assert ar5 == 2

block: # cycle tests
  let
    a = @[1, 2, 3]
    b: seq[int] = @[]
    c = [1, 2, 3]

  doAssert a.cycle(3) == @[1, 2, 3, 1, 2, 3, 1, 2, 3]
  doAssert a.cycle(0) == @[]
  #doAssert a.cycle(-1) == @[] # will not compile!
  doAssert b.cycle(3) == @[]
  doAssert c.cycle(3) == @[1, 2, 3, 1, 2, 3, 1, 2, 3]
  doAssert c.cycle(0) == @[]

block: # repeat tests
  assert repeat(10, 5) == @[10, 10, 10, 10, 10]
  assert repeat(@[1, 2, 3], 2) == @[@[1, 2, 3], @[1, 2, 3]]
  assert repeat([1, 2, 3], 2) == @[[1, 2, 3], [1, 2, 3]]

block: # deduplicates test
  let
    dup1 = @[1, 1, 3, 4, 2, 2, 8, 1, 4]
    dup2 = @["a", "a", "c", "d", "d"]
    dup3 = [1, 1, 3, 4, 2, 2, 8, 1, 4]
    dup4 = ["a", "a", "c", "d", "d"]
    unique1 = deduplicate(dup1)
    unique2 = deduplicate(dup2)
    unique3 = deduplicate(dup3)
    unique4 = deduplicate(dup4)
    unique5 = deduplicate(dup1.sorted, true)
    unique6 = deduplicate(dup2, true)
    unique7 = deduplicate(dup3.sorted, true)
    unique8 = deduplicate(dup4, true)
  assert unique1 == @[1, 3, 4, 2, 8]
  assert unique2 == @["a", "c", "d"]
  assert unique3 == @[1, 3, 4, 2, 8]
  assert unique4 == @["a", "c", "d"]
  assert unique5 == @[1, 2, 3, 4, 8]
  assert unique6 == @["a", "c", "d"]
  assert unique7 == @[1, 2, 3, 4, 8]
  assert unique8 == @["a", "c", "d"]

block: # zip test
  let
    short = @[1, 2, 3]
    long = @[6, 5, 4, 3, 2, 1]
    words = @["one", "two", "three"]
    ashort = [1, 2, 3]
    along = [6, 5, 4, 3, 2, 1]
    awords = ["one", "two", "three"]
    zip1 = zip(short, long)
    zip2 = zip(short, words)
    zip3 = zip(ashort, along)
  assert zip1 == @[(1, 6), (2, 5), (3, 4)]
  assert zip2 == @[(1, "one"), (2, "two"), (3, "three")]
  assert zip3 == @[(1, 6), (2, 5), (3, 4)]
  assert zip1[2][1] == 4
  assert zip2[2][1] == "three"
  assert zip3[2][1] == 4
  when (NimMajor, NimMinor) <= (1, 0):
    let
      # In Nim 1.0.x and older, zip returned a seq of tuple strictly
      # with fields named "a" and "b".
      zipAb = zip(ashort, awords)
    assert zipAb == @[(a: 1, b: "one"), (2, "two"), (3, "three")]
    assert zipAb[2].b == "three"
  else:
    let
      # As zip returns seq of anonymous tuples, they can be assigned
      # to any variable that's a sequence of named tuples too.
      zipXy: seq[tuple[x: int, y: string]] = zip(ashort, awords)
      zipMn: seq[tuple[m: int, n: string]] = zip(ashort, words)
    assert zipXy == @[(x: 1, y: "one"), (2, "two"), (3, "three")]
    assert zipMn == @[(m: 1, n: "one"), (2, "two"), (3, "three")]
    assert zipXy[2].y == "three"
    assert zipMn[2].n == "three"

block: # distribute tests
  let numbers = @[1, 2, 3, 4, 5, 6, 7]
  doAssert numbers.distribute(3) == @[@[1, 2, 3], @[4, 5], @[6, 7]]
  doAssert numbers.distribute(6)[0] == @[1, 2]
  doAssert numbers.distribute(6)[5] == @[7]
  let a = @[1, 2, 3, 4, 5, 6, 7]
  doAssert a.distribute(1, true) == @[@[1, 2, 3, 4, 5, 6, 7]]
  doAssert a.distribute(1, false) == @[@[1, 2, 3, 4, 5, 6, 7]]
  doAssert a.distribute(2, true) == @[@[1, 2, 3, 4], @[5, 6, 7]]
  doAssert a.distribute(2, false) == @[@[1, 2, 3, 4], @[5, 6, 7]]
  doAssert a.distribute(3, true) == @[@[1, 2, 3], @[4, 5], @[6, 7]]
  doAssert a.distribute(3, false) == @[@[1, 2, 3], @[4, 5, 6], @[7]]
  doAssert a.distribute(4, true) == @[@[1, 2], @[3, 4], @[5, 6], @[7]]
  doAssert a.distribute(4, false) == @[@[1, 2], @[3, 4], @[5, 6], @[7]]
  doAssert a.distribute(5, true) == @[@[1, 2], @[3, 4], @[5], @[6], @[7]]
  doAssert a.distribute(5, false) == @[@[1, 2], @[3, 4], @[5, 6], @[7], @[]]
  doAssert a.distribute(6, true) == @[@[1, 2], @[3], @[4], @[5], @[6], @[7]]
  doAssert a.distribute(6, false) == @[
    @[1, 2], @[3, 4], @[5, 6], @[7], @[], @[]]
  doAssert a.distribute(8, false) == a.distribute(8, true)
  doAssert a.distribute(90, false) == a.distribute(90, true)
  var b = @[0]
  for f in 1 .. 25: b.add(f)
  doAssert b.distribute(5, true)[4].len == 5
  doAssert b.distribute(5, false)[4].len == 2

block: # map test
  let
    numbers = @[1, 4, 5, 8, 9, 7, 4]
    anumbers = [1, 4, 5, 8, 9, 7, 4]
    m1 = map(numbers, proc(x: int): int = 2*x)
    m2 = map(anumbers, proc(x: int): int = 2*x)
  assert m1 == @[2, 8, 10, 16, 18, 14, 8]
  assert m2 == @[2, 8, 10, 16, 18, 14, 8]

block: # apply test
  var a = @["1", "2", "3", "4"]
  apply(a, proc(x: var string) = x &= "42")
  assert a == @["142", "242", "342", "442"]

block: # filter proc test
  let
    colors = @["red", "yellow", "black"]
    acolors = ["red", "yellow", "black"]
    f1 = filter(colors, proc(x: string): bool = x.len < 6)
    f2 = filter(colors) do (x: string) -> bool: x.len > 5
    f3 = filter(acolors, proc(x: string): bool = x.len < 6)
    f4 = filter(acolors) do (x: string) -> bool: x.len > 5
  assert f1 == @["red", "black"]
  assert f2 == @["yellow"]
  assert f3 == @["red", "black"]
  assert f4 == @["yellow"]

block: # filter iterator test
  let numbers = @[1, 4, 5, 8, 9, 7, 4]
  let anumbers = [1, 4, 5, 8, 9, 7, 4]
  assert toSeq(filter(numbers, proc (x: int): bool = x mod 2 == 0)) ==
    @[4, 8, 4]
  assert toSeq(filter(anumbers, proc (x: int): bool = x mod 2 == 0)) ==
    @[4, 8, 4]

block: # keepIf test
  var floats = @[13.0, 12.5, 5.8, 2.0, 6.1, 9.9, 10.1]
  keepIf(floats, proc(x: float): bool = x > 10)
  assert floats == @[13.0, 12.5, 10.1]

block: # delete tests
  let outcome = @[1, 1, 1, 1, 1, 1, 1, 1]
  var dest = @[1, 1, 1, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1]
  dest.delete(3, 8)
  assert outcome == dest, """\
  Deleting range 3-9 from [1,1,1,2,2,2,2,2,2,1,1,1,1,1]
  is [1,1,1,1,1,1,1,1]"""
  var x = @[1, 2, 3]
  x.delete(100, 100)
  assert x == @[1, 2, 3]

block: # insert tests
  var dest = @[1, 1, 1, 1, 1, 1, 1, 1]
  let
    src = @[2, 2, 2, 2, 2, 2]
    outcome = @[1, 1, 1, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1]
  dest.insert(src, 3)
  assert dest == outcome, """\
  Inserting [2,2,2,2,2,2] into [1,1,1,1,1,1,1,1]
  at 3 is [1,1,1,2,2,2,2,2,2,1,1,1,1,1]"""

block: # filterIt test
  let
    temperatures = @[-272.15, -2.0, 24.5, 44.31, 99.9, -113.44]
    acceptable = filterIt(temperatures, it < 50 and it > -10)
    notAcceptable = filterIt(temperatures, it > 50 or it < -10)
  assert acceptable == @[-2.0, 24.5, 44.31]
  assert notAcceptable == @[-272.15, 99.9, -113.44]

block: # keepItIf test
  var candidates = @["foo", "bar", "baz", "foobar"]
  keepItIf(candidates, it.len == 3 and it[0] == 'b')
  assert candidates == @["bar", "baz"]

block: # all
  let
    numbers = @[1, 4, 5, 8, 9, 7, 4]
    anumbers = [1, 4, 5, 8, 9, 7, 4]
    len0seq: seq[int] = @[]
  assert all(numbers, proc (x: int): bool = return x < 10) == true
  assert all(numbers, proc (x: int): bool = return x < 9) == false
  assert all(len0seq, proc (x: int): bool = return false) == true
  assert all(anumbers, proc (x: int): bool = return x < 10) == true
  assert all(anumbers, proc (x: int): bool = return x < 9) == false

block: # allIt
  let
    numbers = @[1, 4, 5, 8, 9, 7, 4]
    anumbers = [1, 4, 5, 8, 9, 7, 4]
    len0seq: seq[int] = @[]
  assert allIt(numbers, it < 10) == true
  assert allIt(numbers, it < 9) == false
  assert allIt(len0seq, false) == true
  assert allIt(anumbers, it < 10) == true
  assert allIt(anumbers, it < 9) == false

block: # any
  let
    numbers = @[1, 4, 5, 8, 9, 7, 4]
    anumbers = [1, 4, 5, 8, 9, 7, 4]
    len0seq: seq[int] = @[]
  assert any(numbers, proc (x: int): bool = return x > 8) == true
  assert any(numbers, proc (x: int): bool = return x > 9) == false
  assert any(len0seq, proc (x: int): bool = return true) == false
  assert any(anumbers, proc (x: int): bool = return x > 8) == true
  assert any(anumbers, proc (x: int): bool = return x > 9) == false

block: # anyIt
  let
    numbers = @[1, 4, 5, 8, 9, 7, 4]
    anumbers = [1, 4, 5, 8, 9, 7, 4]
    len0seq: seq[int] = @[]
  assert anyIt(numbers, it > 8) == true
  assert anyIt(numbers, it > 9) == false
  assert anyIt(len0seq, true) == false
  assert anyIt(anumbers, it > 8) == true
  assert anyIt(anumbers, it > 9) == false

block: # toSeq test
  block:
    let
      numeric = @[1, 2, 3, 4, 5, 6, 7, 8, 9]
      oddNumbers = toSeq(filter(numeric) do (x: int) -> bool:
        if x mod 2 == 1:
          result = true)
    assert oddNumbers == @[1, 3, 5, 7, 9]

  block:
    doAssert [1, 2].toSeq == @[1, 2]
    doAssert @[1, 2].toSeq == @[1, 2]

    doAssert @[1, 2].toSeq == @[1, 2]
    doAssert toSeq(@[1, 2]) == @[1, 2]

  block:
    iterator myIter(seed: int): auto =
      for i in 0..<seed:
        yield i
    doAssert toSeq(myIter(2)) == @[0, 1]

  block:
    iterator myIter(): auto {.inline.} =
      yield 1
      yield 2

    doAssert myIter.toSeq == @[1, 2]
    doAssert toSeq(myIter) == @[1, 2]

  block:
    iterator myIter(): int {.closure.} =
      yield 1
      yield 2

    doAssert myIter.toSeq == @[1, 2]
    doAssert toSeq(myIter) == @[1, 2]

  block:
    proc myIter(): auto =
      iterator ret(): int {.closure.} =
        yield 1
        yield 2
      result = ret

    doAssert myIter().toSeq == @[1, 2]
    doAssert toSeq(myIter()) == @[1, 2]

  block:
    proc myIter(n: int): auto =
      var counter = 0
      iterator ret(): int {.closure.} =
        while counter < n:
          yield counter
          counter.inc
      result = ret

    block:
      let myIter3 = myIter(3)
      doAssert myIter3.toSeq == @[0, 1, 2]
    block:
      let myIter3 = myIter(3)
      doAssert toSeq(myIter3) == @[0, 1, 2]
    block:
      # makes sure this does not hang forever
      doAssert myIter(3).toSeq == @[0, 1, 2]
      doAssert toSeq(myIter(3)) == @[0, 1, 2]

block:
  # tests https://github.com/nim-lang/Nim/issues/7187
  counter = 0
  let ret = toSeq(@[1, 2, 3].identity().filter(proc (x: int): bool = x < 3))
  doAssert ret == @[1, 2]
  doAssert counter == 1
block: # foldl tests
  let
    numbers = @[5, 9, 11]
    addition = foldl(numbers, a + b)
    subtraction = foldl(numbers, a - b)
    multiplication = foldl(numbers, a * b)
    words = @["nim", "is", "cool"]
    concatenation = foldl(words, a & b)
  assert addition == 25, "Addition is (((5)+9)+11)"
  assert subtraction == -15, "Subtraction is (((5)-9)-11)"
  assert multiplication == 495, "Multiplication is (((5)*9)*11)"
  assert concatenation == "nimiscool"

block: # foldr tests
  let
    numbers = @[5, 9, 11]
    addition = foldr(numbers, a + b)
    subtraction = foldr(numbers, a - b)
    multiplication = foldr(numbers, a * b)
    words = @["nim", "is", "cool"]
    concatenation = foldr(words, a & b)
  assert addition == 25, "Addition is (5+(9+(11)))"
  assert subtraction == 7, "Subtraction is (5-(9-(11)))"
  assert multiplication == 495, "Multiplication is (5*(9*(11)))"
  assert concatenation == "nimiscool"
  doAssert toSeq(1..3).foldr(a + b) == 6 # issue #14404

block: # mapIt tests
  counter = 0
  var
    nums = @[1, 2, 3, 4]
    strings = nums.identity.mapIt($(4 * it))
  doAssert counter == 1
  doAssert strings == @["4", "8", "12", "16"]

block: # applyIt tests
  const expected = @[3, 6, 9]
  block:
    var a = @[1, 2, 3]
    a.applyIt(it * 3)
    doAssert a == expected

  block:
    var a = @[1,2,3]
    applyIt a, it*3
    doAssert a == expected

  block:
    var count = 0
    applyIt (var a = @[1,2,3]; count.inc; a), it*3
    doAssert count == 1
    doAssert a == expected

  block:
    proc fn(a: var openArray[int]) =
      applyIt(a, it*3)
    var a = @[1,2,3]
    fn(a)
    doAssert a == expected

  block:
    var count = 0
    proc fn(a: var openArray[int]) =
      applyIt((count.inc; a), it*3)
    var a = @[1,2,3]
    fn(a)
    doAssert a == expected
    doAssert count == 1

  block:
    template bar() =
      let a = @[1,2,3]
      applyIt a, it*3
      doAssert a == expected
    doAssert not compiles(bar()) # because of `let`

  block:
    template bar() =
      proc fn(a: openArray[int]) =
        applyIt(a, it*3)
    doAssert not compiles(bar()) # because of `let` param

block: # newSeqWith tests
  var seq2D = newSeqWith(4, newSeq[bool](2))
  seq2D[0][0] = true
  seq2D[1][0] = true
  seq2D[0][1] = true
  doAssert seq2D == @[@[true, true], @[true, false], @[false, false], @[false, false]]

block: # mapLiterals tests
  let x = mapLiterals([0.1, 1.2, 2.3, 3.4], int)
  doAssert x is array[4, int]
  doAssert mapLiterals((1, ("abc"), 2), float, nested = false) ==
    (float(1), "abc", float(2))
  doAssert mapLiterals(([1], ("abc"), 2), `$`, nested = true) ==
    (["1"], "abc", "2")

block: # mapIt with openArray
  counter = 0
  proc foo(x: openArray[int]): seq[int] = x.mapIt(it * 10)
  doAssert foo([identity(1), identity(2)]) == @[10, 20]
  doAssert counter == 2

block: # mapIt with direct openArray
  proc foo1(x: openArray[int]): seq[int] = x.mapIt(it * 10)
  counter = 0
  doAssert foo1(openArray[int]([identity(1), identity(2)])) == @[10, 20]
  doAssert counter == 2

  # Corner cases (openArray literals should not be common)
  template foo2(x: openArray[int]): seq[int] = x.mapIt(it * 10)
  counter = 0
  doAssert foo2(openArray[int]([identity(1), identity(2)])) == @[10, 20]
  # TODO: this fails; not sure how to fix this case
  # doAssert counter == 2

  counter = 0
  doAssert openArray[int]([identity(1), identity(2)]).mapIt(it) == @[1, 2]
  # ditto
  # doAssert counter == 2

block: # mapIt empty test, see https://github.com/nim-lang/Nim/pull/8584#pullrequestreview-144723468
  # NOTE: `[].mapIt(it)` is illegal, just as `let a = @[]` is (lacks type
  # of elements)
  doAssert: not compiles(mapIt(@[], it))
  doAssert: not compiles(mapIt([], it))
  doAssert newSeq[int](0).mapIt(it) == @[]

block: # mapIt redifinition check, see https://github.com/nim-lang/Nim/issues/8580
  let s2 = [1, 2].mapIt(it)
  doAssert s2 == @[1, 2]

block:
  counter = 0
  doAssert [1, 2].identity().mapIt(it*2).mapIt(it*10) == @[20, 40]
  # https://github.com/nim-lang/Nim/issues/7187 test case
  doAssert counter == 1

block: # mapIt with invalid RHS for `let` (#8566)
  type X = enum
    A, B
  doAssert mapIt(X, $it) == @["A", "B"]

block:
  # bug #9093
  let inp = "a:b,c:d"

  let outp = inp.split(",").mapIt(it.split(":"))
  doAssert outp == @[@["a", "b"], @["c", "d"]]


block:
  proc iter(len: int): auto =
    result = iterator(): int =
      for i in 0..<len:
        yield i

  doAssert: iter(3).mapIt(2*it).foldl(a + b) == 6

when not defined(testing):
  echo "Finished doc tests"
