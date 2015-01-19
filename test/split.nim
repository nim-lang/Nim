import unittest
include nre

suite "string splitting":
  test "splitting strings":
    check("1 2 3 4 5 6 ".split(re" ") == @["1", "2", "3", "4", "5", "6", ""])
    check("1  2  ".split(re(" ")) == @["1", "", "2", "", ""])
    check("1 2".split(re(" ")) == @["1", "2"])
    check("foo".split(re("foo")) == @["", ""])
    check("".split(re"foo") == newSeq[string]())

  test "captured patterns":
    check("12".split(re"(\d)") == @["", "1", "", "2", ""])

  test "maxsplit":
    check("123".split(re"", maxsplit = 1) == @["1", "23"])
    check("123".split(re"", maxsplit = 0) == @["123"])
    check("123".split(re"", maxsplit = -1) == @["1", "2", "3"])

  test "split with 0-length match":
    check("12345".split(re("")) == @["1", "2", "3", "4", "5"])
    check("".split(re"") == newSeq[string]())
    check("word word".split(re"\b") == @["word", " ", "word"])
