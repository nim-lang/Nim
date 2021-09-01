discard """
  errormsg: "s1 can raise an unlisted exception: CatchableError"
  line: 27
"""

{.push warningAsError[Effect]: on.}
{.experimental: "strictEffects".}

# bug #18376

{.push raises: [Defect].}
type Call = proc (x: int): int {.gcsafe, raises: [Defect, CatchableError].}

type Bar* = object
  foo*: Call

proc passOn*(x: Call) = discard

proc barCal(b: var Bar, s: string, s1: Call) =
  #compiler complains that his line can throw CatchableError
  passOn s1


proc passOnB*(x: Call) {.effectsOf: x.} = discard

proc barCal2(b: var Bar, s: string, s1: Call) =
  passOnB s1
