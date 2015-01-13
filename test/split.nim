import unittest
include nre

suite "string splitting":
  test "splitting strings":
    check(initRegex("").split("12345") == @["1", "2", "3", "4", "5"])
    check(initRegex(" ", "S").split("1 2 3 4 5 6 ") == @["1", "2", "3", "4", "5", "6", ""])
    check(initRegex(" ", "S").split("1  2  ") == @["1", "", "2", "", ""])
    check(initRegex(" ", "S").split("1 2") == @["1", "2"])
