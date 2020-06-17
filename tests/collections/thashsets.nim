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
