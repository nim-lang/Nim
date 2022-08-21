discard """
  ccodecheck: "__restrict__"
  action: compile
  joinable: false
"""

# see bug #16027
iterator myitems(s: seq[int]): int =
  var data {.codegenDecl: "$# __restrict__ $#".} : ptr int = nil
  yield 1

for i in @[1].myitems:
  discard
