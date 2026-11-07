discard """
  errormsg: "type mismatch"
  line: 9
"""

# bug #12995: a generic routine passed to itself used to reach the C code
# generator with an unresolved `int | proc` parameter
proc g(_: int | proc(_: int): int): int {.discardable.} = 0
g g
