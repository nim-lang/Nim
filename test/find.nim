import unittest, sequtils, nre

suite "find":
  test "find text":
    check("3213a".find(re"[a-z]").match == "a")
    check(toSeq(findIter("1 2 3 4 5 6 7 8 ", re" ")).map(
      proc (a: RegexMatch): string = a.match
    ) == @[" ", " ", " ", " ", " ", " ", " ", " "])

  test "find bounds":
    check(toSeq(findIter("1 2 3 4 5 ", re" ")).map(
      proc (a: RegexMatch): Slice[int] = a.matchBounds
    ) == @[1..2, 3..4, 5..6, 7..8, 9..10])

  test "overlapping find":
    check("222".findAll(re"22") == @["22"])
    check("2222".findAll(re"22") == @["22", "22"])

  test "len 0 find":
    check("".findAll(re"\ ") == newSeq[string]())
    check("".findAll(re"") == @[""])
