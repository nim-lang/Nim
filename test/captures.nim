import unittest
include nre

suite "captures":
  test "map capture names to numbers":
    check(getNameToNumberTable(initRegex("(?<v1>1(?<v2>2(?<v3>3))(?'v4'4))()")) == 
      { "v1" : 1, "v2" : 2, "v3" : 3, "v4" : 4 }.toTable())
