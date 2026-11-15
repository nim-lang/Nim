discard """
action: compile
"""

# bug #17583

{.push raises: [Defect].}

include "system/inclrtl"

{.pop.}

proc foo* =
  raise newException(CatchableError, "boo!")

{.push raises: [Defect].}
