
discard """
  cmd: "nim $target -d:release $options -r $file"
  matrix: "--mm:refc; --mm:arc;"
"""
{.passC: "-fsanitize=undefined -fsanitize-undefined-trap-on-error -Wall -Wextra -pedantic -flto".}
{.passL: "-fsanitize=undefined -fsanitize-undefined-trap-on-error -flto".}

type ForkedEpochInfo = object
  case kind: bool
  of true, false: discard
var info = ForkedEpochInfo(kind: true)
doAssert info.kind
info.kind = false
doAssert not info.kind
