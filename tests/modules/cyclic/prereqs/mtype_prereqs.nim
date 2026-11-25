import ../ttype_prereqs {.cyclic.}

const M = 2
type
  B* = object
    y*: int
    a*: array[M, A] # of the partner module, and a constant of its own

proc partnerValue*(): int = 7
proc useB*(b: B): int = b.y
