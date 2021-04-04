#
#
#           The Nim Compiler
#        (c) Copyright 2021 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## `guards.nim` reimplementation.

type
  VarId* = distinct int32
  VarVarLe* = object    # semantics: a <= b + c
    a*, b*: VarId
    c*: int64
  VarLe* = object    # semantics: a <= c
    a*: VarId
    c*: int64
  ValLe* = object    # semantics: c <= a
    c*: int64
    a*: VarId

  Facts* = object
    x*: seq[VarVarLe]
    y*: seq[VarLe]
    z*: seq[ValLe]

proc `==`*(a, b: VarId): bool {.borrow.}

proc simpleImplies(facts: Facts; v: VarVarLe): bool =
  for f in facts.x:
    if f.a == v.a and f.b == v.b:
      # if we know that  a <= b + 3 we can infer that a <= b + 4
      if f.c <= v.c: return true

proc implies*(facts: Facts; v: VarLe): bool =
  for f in facts.y:
    if f.a == v.a:
      # if we know that a <= 4 we can infer that a <= 6
      if f.c <= v.c: return true

proc implies*(facts: Facts; v: ValLe): bool =
  for f in facts.z:
    if f.a == v.a:
      # if we know that 4 <= a we can infer that 3 <= a
      if v.c <= f.c: return true

#[

There is a single inference rule:

  a <= b + 4
  b <= c + 5

-->

  a <= c + 5 + 4

]#

import intsets

proc traverseAllPathsUtil(facts: Facts; u: VarId; d: VarVarLe; nodeIndex: int;
                          visited: var IntSet; path: var seq[int]; res: var bool) =
  visited.incl nodeIndex
  path.add nodeIndex
  if u == d.b:
    # See if the solution suits us:
    var sum = 0'i64
    for j in path:
      sum += facts.x[j].c
    if sum <= d.c: res = true
  else:
    for i in 0..high(facts.x):
      if facts.x[i].a == u:
        if i notin visited:
          traverseAllPathsUtil(facts, facts.x[i].b, d, i, visited, path, res)
  discard path.pop
  visited.excl nodeIndex


proc traverseAllPaths(facts: Facts; s: VarId; d: VarVarLe; res: var bool) =
  var visited = initIntSet()
  var path = newSeq[int]()

  for i in 0..high(facts.x):
    if facts.x[i].a == s:
      traverseAllPathsUtil(facts, facts.x[i].b, d, i, visited, path, res)

proc complexImplies(facts: Facts; v: VarVarLe): bool =
  traverseAllPaths(facts, v.a, v, result)

proc implies*(facts: Facts; v: VarVarLe): bool =
  result = simpleImplies(facts, v) or complexImplies(facts, v)

when isMainModule:
  proc main =
    let a = VarId(1)
    let b = VarId(2)
    let d = VarId(3)
    let z = VarId(4)

    let facts = Facts(x: @[
      VarVarLe(a: a, b: b, c: 0),
      VarVarLe(a: b, b: d, c: 13),
      VarVarLe(a: d, b: z, c: 34)
      ], y: @[], z: @[])

    echo facts.implies VarVarLe(a: a, b: z, c: 443)

  main()
