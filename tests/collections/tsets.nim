import sets

block setEquality:
  var
    a = initSet[int]()
    b = initSet[int]()
    c = initSet[string]()

  for i in 0..5: a.incl(i)
  for i in 1..6: b.incl(i)
  for i in 0..5: c.incl($i)

  doAssert map(a, proc(x: int): int = x + 1) == b
  doAssert map(a, proc(x: int): string = $x) == c


block setsContainingTuples:
  var set = initSet[tuple[i: int, i64: int64, f: float]]()
  set.incl( (i: 123, i64: 123'i64, f: 3.14) )
  doAssert set.contains( (i: 123, i64: 123'i64, f: 3.14) )
  doAssert( not set.contains( (i: 456, i64: 789'i64, f: 2.78) ) )


block setWithTuplesWithSeqs:
  var s = initSet[tuple[s: seq[int]]]()
  s.incl( (s: @[1, 2, 3]) )
  doAssert s.contains( (s: @[1, 2, 3]) )
  doAssert( not s.contains((s: @[4, 5, 6])) )


block setWithSequences:
  var s = initSet[seq[int]]()
  s.incl( @[1, 2, 3] )
  doAssert s.contains(@[1, 2, 3])
  doAssert( not s.contains(@[4, 5, 6]) )


