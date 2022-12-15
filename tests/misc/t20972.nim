
discard """
  matrix: "--gc:refc; --gc:arc"
"""
{.passC: "-fsanitize=undefined -Wall -Wextra -pedantic -flto".}
{.passL: "-fsanitize=undefined -flto".}

type ForkedEpochInfo = object
  case kind: bool
  of true, false: discard
var info = ForkedEpochInfo(kind: true)
doAssert info.kind
info.kind = false
doAssert not info.kind
