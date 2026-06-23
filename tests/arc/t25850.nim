discard """
  cmd: '''nim c --mm:orc --expandArc:uIf --expandArc:uCase $file'''
  nimout: '''
--expandArc: uIf

block :tmp:
  let s = w()
  if true:
    r[] = s
  else:
    r[] = s
-- end of expandArc ------------------------
--expandArc: uCase

block :tmp:
  let s = w()
  case n
  of 0:
    r[] = s
  else:
    r[] = w()
-- end of expandArc ------------------------
'''
"""

# bug #25850
# Assigning an expression-based control flow construct (an `if`/`case` nested in
# a `block`) must distribute the assignment directly into the leaf branches
# instead of creating redundant intermediate temporaries per branch.

proc w(): array[1000, byte] {.noinline.} = discard

proc uIf(r: ptr array[1000, byte]) =
  r[] = (block:
    let s = w()
    if true: s else: s)

proc uCase(r: ptr array[1000, byte], n: int) =
  r[] = (block:
    let s = w()
    case n
    of 0: s
    else: w())

var d: array[1000, byte]
uIf(addr d)
uCase(addr d, 0)
