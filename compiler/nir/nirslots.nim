#
#
#           The Nim Compiler
#        (c) Copyright 2023 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Management of slots. Similar to "register allocation"
## in lower level languages.

import std / [assertions, tables]
import nirtypes, nirinsts

type
  SlotManagerFlag* = enum
    ReuseTemps,
    ReuseVars
  SlotKind* = enum
    Temp, Perm
  SlotManager* = object # "register allocator"
    live: Table[SymId, (SlotKind, TypeId)]
    dead: Table[TypeId, seq[SymId]]
    flags: set[SlotManagerFlag]
    inScope: seq[SymId]
    locGen: ref int

proc initSlotManager*(flags: set[SlotManagerFlag]; generator: ref int): SlotManager {.inline.} =
  SlotManager(flags: flags, locGen: generator)

proc allocRaw(m: var SlotManager; t: TypeId; f: SlotManagerFlag; k: SlotKind): SymId {.inline.} =
  if f in m.flags and m.dead.hasKey(t) and m.dead[t].len > 0:
    result = m.dead[t].pop()
  else:
    result = SymId(m.locGen[])
    inc m.locGen[]
    m.inScope.add result
  m.live[result] = (k, t)

proc allocTemp*(m: var SlotManager; t: TypeId): SymId {.inline.} =
  result = allocRaw(m, t, ReuseTemps, Temp)

proc allocVar*(m: var SlotManager; t: TypeId): SymId {.inline.} =
  result = allocRaw(m, t, ReuseVars, Perm)

proc freeLoc*(m: var SlotManager; s: SymId) =
  let t = m.live.getOrDefault(s)
  assert t[1].int != 0
  m.live.del s
  m.dead.mgetOrPut(t[1], @[]).add s

proc freeTemp*(m: var SlotManager; s: SymId) =
  let t = m.live.getOrDefault(s)
  if t[1].int != 0 and t[0] == Temp:
    m.live.del s
    m.dead.mgetOrPut(t[1], @[]).add s

iterator stillAlive*(m: SlotManager): (SymId, TypeId) =
  for k, v in pairs(m.live):
    yield (k, v[1])

proc getType*(m: SlotManager; s: SymId): TypeId {.inline.} = m.live[s][1]

proc openScope*(m: var SlotManager) =
  m.inScope.add SymId(-1) # add marker

proc closeScope*(m: var SlotManager) =
  var i = m.inScope.len - 1
  while i >= 0:
    if m.inScope[i] == SymId(-1):
      m.inScope.setLen i
      break
    dec i

when isMainModule:
  var m = initSlotManager({ReuseTemps}, new(int))

  var g = initTypeGraph()

  let a = g.openType ArrayTy
  g.addBuiltinType Int8Id
  g.addArrayLen 5'u64
  let finalArrayType = sealType(g, a)

  let obj = g.openType ObjectDecl
  g.addName "MyType"

  g.addField "p", finalArrayType
  let objB = sealType(g, obj)

  let x = m.allocTemp(objB)
  assert x.int == 0

  let y = m.allocTemp(objB)
  assert y.int == 1

  let z = m.allocTemp(Int8Id)
  assert z.int == 2

  m.freeLoc y
  let y2 = m.allocTemp(objB)
  assert y2.int == 1


