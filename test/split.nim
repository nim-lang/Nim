import unittest
include nre

suite "string splitting":
  test "splitting strings":
    check("12345".split(initRegex("")) == @["1", "2", "3", "4", "5"])
    check("1 2 3 4 5 6 ".split(re" ") == @["1", "2", "3", "4", "5", "6", ""])
    check("1  2  ".split(initRegex(" ")) == @["1", "", "2", "", ""])
    check("1 2".split(initRegex(" ")) == @["1", "2"])
    check("foo".split(initRegex("foo")) == @["", ""])

  test "captured patterns":
    check("12".split(re"(\d)") == @["", "1", "", "2", ""])

  test "maxsplit":
    check("123".split(re"", maxsplit = 1) == @["1", "23"])
    check("123".split(re"", maxsplit = 0) == @["123"])
    check("123".split(re"", maxsplit = -1) == @["1", "2", "3"])
