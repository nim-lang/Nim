include nre, unittest

suite "match":
  test "upper bound must be exclusive":
    check("abc".match(re"abc", endpos = 0) == nil)
    check("abc".match(re"abc", endpos = 3) != nil)
