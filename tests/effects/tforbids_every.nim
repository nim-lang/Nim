discard """
  action: compile
  errormsg: "b() has an illegal effect: B"
  line: 15
"""

# Every effect listed in `.forbids` is forbidden, not only the first one.

type
  A = object of RootEffect
  B = object of RootEffect

proc b() {.tags: [B].} = discard

proc test() {.forbids: [A, B].} = b()
