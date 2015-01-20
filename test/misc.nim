import unittest, nre

suite "Misc tests":
  test "unicode":
    check("".find(re("", "8")).match == "")
