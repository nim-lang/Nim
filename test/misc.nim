import unittest, nre

suite "Misc tests":
  test "unicode":
    check("".find(re("", "8")).match == "")
    check("перевірка".replace(re(r"\w", "uW"), "") == "")

