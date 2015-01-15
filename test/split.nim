import unittest
include nre

suite "string splitting":
  test "splitting strings":
    check("12345".split(initRegex("")) == @["1", "2", "3", "4", "5"])
    check("1 2 3 4 5 6 ".split(initRegex(" ", "S")) == @["1", "2", "3", "4", "5", "6", ""])
    check("1  2  ".split(initRegex(" ", "S")) == @["1", "", "2", "", ""])
    check("1 2".split(initRegex(" ", "S")) == @["1", "2"])
    check("foo".split(initRegex("foo")) == @["", ""])
