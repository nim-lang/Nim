discard """
  action: compile
  errormsg: "c() has an illegal effect: NestedPoll"
  line: 18
"""

type
  NestedPoll* = object of RootEffect

proc poll*() {.tags: [NestedPoll].} =
  discard

proc a*() = poll()
proc b*() = a()
proc c*() = b()

proc test*() {.forbids: [NestedPoll].} =
  c()
