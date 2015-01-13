import unittest
include nre

suite "find":
  test "find text":
    check(initRegex(r"[a-z]").find("3213a").get.match == "a")
    check(initRegex(r" ", "S").findAll("1 2 3 4 5 6 7 8 ").map(
      proc (a: RegexMatch): string = a.match
    ) == @[" ", " ", " ", " ", " ", " ", " ", " "])

  test "find bounds":
    check(initRegex(r" ", "S").findAll("1 2 3 4 5 ").map(
      proc (a: RegexMatch): Slice[int] = a.matchBounds
    ) == @[1..2, 3..4, 5..6, 7..8, 9..10])
