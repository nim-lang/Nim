include nre, unittest

suite "match":
  test "upper bound must be exclusive":
    check("abc".match(re"abc", endpos = 0) == nil)
    check("abc".match(re"abc", endpos = 3) != nil)

  test "match examples":
    check("abc".match(re"(\w)").captures[0] == "a")
    check("abc".match(re"(?<letter>\w)").captures["letter"] == "a")
    check("abc".match(re"(\w)\w").captures[-1] == "ab")
    check("abc".match(re"(\w)").captureBounds[0].get == 0..1)
    check("abc".match(re"").captureBounds[-1].get == 0..0)
    check("abc".match(re"abc").captureBounds[-1].get == 0..3)

  test "match test cases":
    check("123".match(re"").matchBounds == 0..0)
