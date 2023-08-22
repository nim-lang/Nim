include nre, unittest, optional_nonstrict

block: # match
  block: # upper bound must be inclusive
    check("abc".match(re"abc", endpos = -1) == none(RegexMatch))
    check("abc".match(re"abc", endpos = 1) == none(RegexMatch))
    check("abc".match(re"abc", endpos = 2) != none(RegexMatch))

  block: # match examples
    check("abc".match(re"(\w)").captures[0] == "a")
    check("abc".match(re"(?<letter>\w)").captures["letter"] == "a")
    check("abc".match(re"(\w)\w").captures[-1] == "ab")
    check("abc".match(re"(\w)").captureBounds[0] == 0 .. 0)
    check("abc".match(re"").captureBounds[-1] == 0 .. -1)
    check("abc".match(re"abc").captureBounds[-1] == 0 .. 2)

  block: # match test cases
    check("123".match(re"").matchBounds == 0 .. -1)
