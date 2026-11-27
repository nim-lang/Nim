discard """
  nimout: '''
nnkSym
nnkSym
nnkSym
nnkSym
nnkSym
'''
"""

# bug #26473: a pragma alias expands to `p` on every use, not `p()`
import std/macros

template p() {.pragma.}
{.pragma: alias, p.}

type O = object
  a {.alias.}: int
  b {.alias.}: int
  c {.alias.}: int

macro show(T: typed) =
  for field in T.getImpl[2][2]:
    echo field[0][1][0].kind

show(O)

proc f1() {.alias.} = discard
proc f2() {.alias.} = discard

macro showProc(f: typed) =
  echo f.getImpl.pragma[0].kind

showProc(f1)
showProc(f2)
doAssert f1.hasCustomPragma(p)
doAssert f2.hasCustomPragma(p)
