import unittest
include nre

suite "find":
  test "find text":
    check("3213a".find(initRegex(r"[a-z]")).match == "a")
    check("1 2 3 4 5 6 7 8 ".findAll(re" ").map(
      proc (a: RegexMatch): string = a.match
    ) == @[" ", " ", " ", " ", " ", " ", " ", " "])

  test "find bounds":
    check("1 2 3 4 5 ".findAll(re" ")).map(
      proc (a: RegexMatch): Slice[int] = a.matchBounds
    ) == @[1..2, 3..4, 5..6, 7..8, 9..10])

  test "overlapping find":
    check("222".findAllStr(re"22") == @["22"])
    check("2222".findAllStr(re"22") == @["22", "22"])

  test "len 0 find":
    check("".findAllStr(re"\ ") == newSeq[string]())
    check("".findAllStr(re"") == @[""])
