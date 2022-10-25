discard """
  matrix: "; --panics:on"
"""

func test =
  if 0 > 10:
    raiseAssert "hey"
test()
