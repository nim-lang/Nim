type
  Indexable = PNode or PType

  TreeRead* = object
  TreeWrite* = object
  TreeBreak* = object
  TreeSafe* = object

  LocRead* {.deprecated.} = TreeRead
  LocWrite* {.deprecated.} = TreeWrite
  LocBreak* {.deprecated.} = TreeBreak
  LocSafe* {.deprecated.} = TreeSafe


proc unsafeAdd(father, son: Indexable) =
  assert son != nil
  when not defined(nimNoNilSeqs):
    if father.sons == nil:
      father.sons = @[]
  father.sons.add son

proc safeAdd*(father, son: Indexable) =
  father.unsafeAdd son

template add*(father, son: PNode | PType) {.deprecated.} =
  father.safeAdd son

proc r*(a: TLoc): Rope {.tags: [TreeRead].} =
  result = a.roap

proc `loc=`*(p: PSym or PType; loc: TLoc) {.tags: [TreeRead, TreeWrite].} =
  when defined(debugTLoc):
    echo "set location"
  assert p.location.k == loc.k or p.location.k == locNone
  assert p.location.roap == nil or $p.location.r == $loc.r
  system.`=`(p.location, loc)

proc loc*(p: PSym or PType): TLoc {.tags: [TreeRead].} =
  result = p.location

proc mloc*(p: PSym or PType): var TLoc {.tags: [TreeRead, TreeWrite].} =
  result = p.location
  when defined(debugTLoc):
    echo "mut loc"

proc setLocation*(p: PSym or PType; a: TLoc) {.tags: [TreeWrite, TreeSafe].} =
  ## this should be run almost nowhere
  p.location = a

proc mr*(a: var TLoc): var Rope {.tags: [TreeRead, TreeWrite].} =
  when defined(debugTLoc):
    echo "get rope mut"
  result = a.roap

proc clearRope*(a: TLoc) {.tags: [TreeWrite].} =
  assert a.roap == nil
  when defined(debugTLoc):
    echo "clear imm"

proc clearRope*(a: var TLoc) {.tags: [TreeWrite].} =
  a.roap = nil
  when defined(debugTLoc):
    echo "clear mut"

proc setRope*(a: TLoc; roap: Rope) {.tags: [TreeWrite].} =
  ## a trap to catch bad attempts to mutate an immutable
  assert roap == nil
  assert a.roap == nil
  when defined(debugTLoc):
    echo "set rope imm"

proc setRope*(a: var TLoc; roap: Rope) {.tags: [TreeWrite].} =
  assert roap != nil
  a.roap = roap
  when defined(debugTLoc):
    echo "set rope mut"

proc setRope*(a: var TLoc; roap: var Rope) {.tags: [TreeWrite].} =
  assert roap != nil
  a.roap = roap
  when defined(debugTLoc):
    echo "set rope remains mut"

when false:
  proc addRope*(a: var TLoc; roap: Rope) {.tags: [TreeWrite].} =
    assert roap != nil
    a.roap.add roap
    when defined(debugTLoc):
      echo "add rope"

proc mergeLoc(a: var TLoc; b: TLoc) {.tags: [TreeRead, TreeWrite].} =
  when defined(debugTLoc):
    echo "mut merge"
  if a.k == locNone:
    assert a.k == low(a.k)
    a.k = b.k
  if a.storage == OnUnknown:
    assert a.storage == low(a.storage)
    a.storage = b.storage
  a.flags = a.flags + b.flags
  if a.lode == nil:
    a.lode = b.lode
  if a.r == nil:
    if b.r == nil:
      a.clearRope
    else:
      a.setRope(b.r)

