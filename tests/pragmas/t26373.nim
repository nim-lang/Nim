discard """
  action: run
"""

# bug #26373: `hasCustomPragma` ignores fields declared under `when`

import std/macros

template marker() {.pragma.}
template other() {.pragma.}
template val(x: int) {.pragma.}

const useA = false

type
  Obj = object
    when true:
      field {.marker.}: int

  Branches = object
    when useA:
      a {.other.}: int
    elif not useA and defined(nimHasNoSuchThing):
      a {.val(1).}: int
    elif sizeof(int) > 0:
      a {.marker, val(2).}: int
    else:
      a {.val(3).}: int
    when defined(nimHasNoSuchThing):
      b {.marker.}: int
    else:
      b: int
      when true:
        c {.val(4).}: int
      else:
        c: int

  Derived = object of RootObj
    when not useA:
      inh {.marker.}: int
  Child = object of Derived

  Gen[T] = object
    when true:
      g {.marker.}: T

doAssert Obj().field.hasCustomPragma(marker)

doAssert Branches().a.hasCustomPragma(marker)
doAssert not Branches().a.hasCustomPragma(other)
doAssert Branches().a.getCustomPragmaVal(val) == 2
doAssert not Branches().b.hasCustomPragma(marker)
doAssert Branches().c.getCustomPragmaVal(val) == 4

doAssert Child().inh.hasCustomPragma(marker)
doAssert Gen[int]().g.hasCustomPragma(marker)
