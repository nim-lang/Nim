import sets, hashes, algorithm


block setEquality:
  var
    a = initHashSet[int]()
    b = initHashSet[int]()
    c = initHashSet[string]()

  for i in 0..5: a.incl(i)
  for i in 1..6: b.incl(i)
  for i in 0..5: c.incl($i)

  doAssert map(a, proc(x: int): int = x + 1) == b
  doAssert map(a, proc(x: int): string = $x) == c


block setsContainingTuples:
  var set = initHashSet[tuple[i: int, i64: int64, f: float]]()
  set.incl( (i: 123, i64: 123'i64, f: 3.14) )
  doAssert set.contains( (i: 123, i64: 123'i64, f: 3.14) )
  doAssert( not set.contains( (i: 456, i64: 789'i64, f: 2.78) ) )


block setWithTuplesWithSeqs:
  var s = initHashSet[tuple[s: seq[int]]]()
  s.incl( (s: @[1, 2, 3]) )
  doAssert s.contains( (s: @[1, 2, 3]) )
  doAssert( not s.contains((s: @[4, 5, 6])) )


block setWithSequences:
  var s = initHashSet[seq[int]]()
  s.incl( @[1, 2, 3] )
  doAssert s.contains(@[1, 2, 3])
  doAssert( not s.contains(@[4, 5, 6]) )

block setClearWorked:
  var s = initHashSet[char]()

  for c in "this is a test":
    s.incl(c)

  doAssert len(s) == 7
  clear(s)
  doAssert len(s) == 0

  s.incl('z')
  for c in "this is a test":
    s.incl(c)

  doAssert len(s) == 8

block orderedSetClearWorked:
  var s = initOrderedSet[char]()

  for c in "eat at joes":
    s.incl(c)

  var r = ""

  for c in items(s):
    add(r, c)

  doAssert r == "eat jos"
  clear(s)

  s.incl('z')
  for c in "eat at joes":
    s.incl(c)

  r = ""
  for c in items(s):
    add(r, c)

  doAssert r == "zeat jos"

block hashForHashedSet:
  let
    seq1 = "This is the test."
    seq2 = "the test is This."
    s1 = seq1.toHashSet()
    s2 = seq2.toHashSet()
  doAssert s1 == s2
  doAssert hash(s1) == hash(s2)

block hashForOrderdSet:
  let
    str = "This is the test."
    rstr = str.reversed

  var
    s1 = initOrderedSet[char]()
    s2 = initOrderedSet[char]()
    r = initOrderedSet[char]()
    expected: Hash
    added: seq[char] = @[]
    reversed: Hash
    radded: seq[char] = @[]

  expected = 0
  for c in str:
    if (not (c in added)):
      expected = expected !& hash(c)
      added.add(c)
    s1.incl(c)
    s2.incl(c)
  expected = !$expected
  doAssert hash(s1) == expected
  doAssert hash(s1) == hash(s2)
  doAssert hash(s1) != hash(r)

  reversed = 0
  for c in rstr:
    if (not (c in radded)):
      reversed = reversed !& hash(c)
      radded.add(c)
    r.incl(c)
  reversed = !$reversed
  doAssert hash(r) == reversed
  doAssert hash(s1) != reversed


proc testModule() =
  ## Internal micro test to validate docstrings and such.
  block lenTest:
    var values: HashSet[int]
    doAssert values.len == 0
    doAssert values.card == 0

  block setIterator:
    type pair = tuple[a, b: int]
    var a, b = initHashSet[pair]()
    a.incl((2, 3))
    a.incl((3, 2))
    a.incl((2, 3))
    for x, y in a.items:
      b.incl((x - 2, y + 1))
    doAssert a.len == b.card
    doAssert a.len == 2
    #echo b

  block setContains:
    var values = initHashSet[int]()
    doAssert(not values.contains(2))
    values.incl(2)
    doAssert values.contains(2)
    values.excl(2)
    doAssert(not values.contains(2))

    values.incl(4)
    var others = toHashSet([6, 7])
    values.incl(others)
    doAssert values.len == 3

    values.init
    doAssert values.containsOrIncl(2) == false
    doAssert values.containsOrIncl(2) == true
    var
      a = toHashSet([1, 2])
      b = toHashSet([1])
    b.incl(2)
    doAssert a == b

  block exclusions:
    var s = toHashSet([2, 3, 6, 7])
    s.excl(2)
    s.excl(2)
    doAssert s.len == 3

    var
      numbers = toHashSet([1, 2, 3, 4, 5])
      even = toHashSet([2, 4, 6, 8])
    numbers.excl(even)
    #echo numbers
    # --> {1, 3, 5}

  block toSeqAndString:
    var a = toHashSet([2, 7, 5])
    var b = initHashSet[int](a.len)
    for x in [2, 7, 5]: b.incl(x)
    doAssert($a == $b)
    #echo a
    #echo toHashSet(["no", "esc'aping", "is \" provided"])

  #block orderedToSeqAndString:
  #  echo toOrderedSet([2, 4, 5])
  #  echo toOrderedSet(["no", "esc'aping", "is \" provided"])

  block setOperations:
    var
      a = toHashSet(["a", "b"])
      b = toHashSet(["b", "c"])
      c = union(a, b)
    doAssert c == toHashSet(["a", "b", "c"])
    var d = intersection(a, b)
    doAssert d == toHashSet(["b"])
    var e = difference(a, b)
    doAssert e == toHashSet(["a"])
    var f = symmetricDifference(a, b)
    doAssert f == toHashSet(["a", "c"])
    doAssert d < a and d < b
    doAssert((a < a) == false)
    doAssert d <= a and d <= b
    doAssert((a <= a))
    # Alias test.
    doAssert a + b == toHashSet(["a", "b", "c"])
    doAssert a * b == toHashSet(["b"])
    doAssert a - b == toHashSet(["a"])
    doAssert a -+- b == toHashSet(["a", "c"])
    doAssert disjoint(a, b) == false
    doAssert disjoint(a, b - a) == true

  block mapSet:
    var a = toHashSet([1, 2, 3])
    var b = a.map(proc (x: int): string = $x)
    doAssert b == toHashSet(["1", "2", "3"])

  block lenTest:
    var values: OrderedSet[int]
    doAssert values.len == 0
    doAssert values.card == 0

  block setIterator:
    type pair = tuple[a, b: int]
    var a, b = initOrderedSet[pair]()
    a.incl((2, 3))
    a.incl((3, 2))
    a.incl((2, 3))
    for x, y in a.items:
      b.incl((x - 2, y + 1))
    doAssert a.len == b.card
    doAssert a.len == 2

  block setPairsIterator:
    var s = toOrderedSet([1, 3, 5, 7])
    var items = newSeq[tuple[a: int, b: int]]()
    for idx, item in s: items.add((idx, item))
    doAssert items == @[(0, 1), (1, 3), (2, 5), (3, 7)]

  block exclusions:
    var s = toOrderedSet([1, 2, 3, 6, 7, 4])

    s.excl(3)
    s.excl(3)
    s.excl(1)
    s.excl(4)

    var items = newSeq[int]()
    for item in s: items.add item
    doAssert items == @[2, 6, 7]

  block: #9005
    var s = initOrderedSet[(int, int)]()
    for i in 0 .. 30: incl(s, (i, 0))
    for i in 0 .. 30: excl(s, (i, 0))
    doAssert s.len == 0

  #block orderedSetIterator:
  #  var a = initOrderedSet[int]()
  #  for value in [9, 2, 1, 5, 1, 8, 4, 2]:
  #    a.incl(value)
  #  for value in a.items:
  #    echo "Got ", value

  block setContains:
    var values = initOrderedSet[int]()
    doAssert(not values.contains(2))
    values.incl(2)
    doAssert values.contains(2)

  block toSeqAndString:
    var a = toOrderedSet([2, 4, 5])
    var b = initOrderedSet[int]()
    for x in [2, 4, 5]: b.incl(x)
    doAssert($a == $b)
    doAssert(a == b) # https://github.com/Araq/Nim/issues/1413

  block initBlocks:
    var a: OrderedSet[int]
    a.init(4)
    a.incl(2)
    a.init
    doAssert a.len == 0
    a = initOrderedSet[int](4)
    a.incl(2)
    doAssert a.len == 1

    var b: HashSet[int]
    b.init(4)
    b.incl(2)
    b.init
    doAssert b.len == 0
    b = initHashSet[int](4)
    b.incl(2)
    doAssert b.len == 1

  block missingOrExcl:
    var s = toOrderedSet([2, 3, 6, 7])
    doAssert s.missingOrExcl(4) == true
    doAssert s.missingOrExcl(6) == false

  block orderedSetEquality:
    type pair = tuple[a, b: int]

    var aa = initOrderedSet[pair]()
    var bb = initOrderedSet[pair]()

    var x = (a: 1, b: 2)
    var y = (a: 3, b: 4)

    aa.incl(x)
    aa.incl(y)

    bb.incl(x)
    bb.incl(y)
    doAssert aa == bb

  block setsWithoutInit:
    var
      a: HashSet[int]
      b: HashSet[int]
      c: HashSet[int]
      d: HashSet[int]
      e: HashSet[int]

    doAssert a.containsOrIncl(3) == false
    doAssert a.contains(3)
    doAssert a.len == 1
    doAssert a.containsOrIncl(3)
    a.incl(3)
    doAssert a.len == 1
    a.incl(6)
    doAssert a.len == 2

    b.incl(5)
    doAssert b.len == 1
    b.excl(5)
    b.excl(c)
    doAssert b.missingOrExcl(5)
    doAssert b.disjoint(c)

    d = b + c
    doAssert d.len == 0
    d = b * c
    doAssert d.len == 0
    d = b - c
    doAssert d.len == 0
    d = b -+- c
    doAssert d.len == 0

    doAssert (d < e) == false
    doAssert d <= e
    doAssert d == e

  block setsWithoutInit:
    var
      a: OrderedSet[int]
      b: OrderedSet[int]
      c: OrderedSet[int]
      d: HashSet[int]


    doAssert a.containsOrIncl(3) == false
    doAssert a.contains(3)
    doAssert a.len == 1
    doAssert a.containsOrIncl(3)
    a.incl(3)
    doAssert a.len == 1
    a.incl(6)
    doAssert a.len == 2

    b.incl(5)
    doAssert b.len == 1
    doAssert b.missingOrExcl(5) == false
    doAssert b.missingOrExcl(5)

    doAssert c.missingOrExcl(9)
    d.incl(c)
    doAssert d.len == 0

testModule()
