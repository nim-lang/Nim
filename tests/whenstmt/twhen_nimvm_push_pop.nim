discard """
  errormsg: "{.pop.} without a corresponding {.push.}"
  line: 8
"""

when nimvm:
  {.push checks: off.}
else: {.pop.}
