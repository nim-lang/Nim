#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Simple alias analysis for the HLO and the code generators.

import
  ast, astalgo, types, trees

import std/intsets

when defined(nimPreviewSlimSystem):
  import std/assertions

type
  TAnalysisResult* = enum
    arNo, arMaybe, arYes

  PartFlag* = enum
    pfStructural    ## use structural prefix-chain detection and tree-walk
    pfBidirectional ## also check reverse direction per field in nkObjConstr

proc isCompileTimeOnlyNode(n: PNode): bool {.inline.} =
  ## `typeof` and typedesc/static values describe types at compile time; they
  ## do not read the runtime location that alias analysis is protecting.
  n.kind == nkTypeOfExpr or (n.typ != nil and n.typ.isCompileTimeOnly)

func sameLocation(a, b: PNode): bool =
  template sameConstIndex(a, b: PNode): bool =
    a.kind in nkLiterals and b.kind in nkLiterals and a.intVal == b.intVal
  var a = a
  var b = b
  while a.kind in {nkHiddenStdConv, nkHiddenSubConv, nkConv}: a = a[1]
  while b.kind in {nkHiddenStdConv, nkHiddenSubConv, nkConv}: b = b[1]
  if a.kind != b.kind: return false
  case a.kind
  of nkSym: result = a.sym.id == b.sym.id
  of nkDotExpr, nkCheckedFieldExpr:
    result = a[1].kind == nkSym and b[1].kind == nkSym and
             sameLocation(a[0], b[0]) and a[1].sym.id == b[1].sym.id
  of nkBracketExpr:
    result = sameLocation(a[0], b[0]) and sameConstIndex(a[1], b[1])
  of nkObjUpConv, nkObjDownConv, nkDerefExpr, nkHiddenDeref:
    result = sameLocation(a[0], b[0])
  else: result = false

proc isAccessorPrefixOf(a, b: PNode): bool =
  var cur = b
  while cur.kind in {nkDotExpr, nkBracketExpr, nkCheckedFieldExpr, nkObjUpConv,
                     nkObjDownConv, nkHiddenDeref, nkDerefExpr,
                     nkHiddenStdConv, nkHiddenSubConv, nkConv}:
    if sameLocation(cur, a): return true
    case cur.kind
    of nkDotExpr, nkBracketExpr, nkCheckedFieldExpr, nkObjUpConv, nkObjDownConv,
       nkHiddenDeref, nkDerefExpr:
      cur = cur[0]
    of nkHiddenStdConv, nkHiddenSubConv, nkConv:
      cur = cur[1]
    else: discard
  result = sameLocation(cur, a)

proc isPartOfAux(a, b: PType, marker: var IntSet): TAnalysisResult

proc isPartOfAux(n: PNode, b: PType, marker: var IntSet): TAnalysisResult =
  result = arNo
  case n.kind
  of nkRecList:
    for i in 0..<n.len:
      result = isPartOfAux(n[i], b, marker)
      if result == arYes: return
  of nkRecCase:
    assert(n[0].kind == nkSym)
    result = isPartOfAux(n[0], b, marker)
    if result == arYes: return
    for i in 1..<n.len:
      case n[i].kind
      of nkOfBranch, nkElse:
        result = isPartOfAux(lastSon(n[i]), b, marker)
        if result == arYes: return
      else: discard "isPartOfAux(record case branch)"
  of nkSym:
    result = isPartOfAux(n.sym.typ, b, marker)
  else: discard

proc isPartOfAux(a, b: PType, marker: var IntSet): TAnalysisResult =
  result = arNo
  if a == nil or b == nil: return
  if containsOrIncl(marker, a.id): return
  if compareTypes(a, b, dcEqIgnoreDistinct): return arYes
  case a.kind
  of tyObject:
    if a.baseClass != nil:
      result = isPartOfAux(a.baseClass.skipTypes(skipPtrs), b, marker)
    if result == arNo: result = isPartOfAux(a.n, b, marker)
  of tyGenericInst, tyDistinct, tyAlias, tySink:
    result = isPartOfAux(skipModifier(a), b, marker)
  of tySet, tyArray:
    result = isPartOfAux(a.elementType, b, marker)
  of tyTuple:
    for aa in a.kids:
      result = isPartOfAux(aa, b, marker)
      if result == arYes: return
  else: discard

proc isPartOf(a, b: PType): TAnalysisResult =
  ## checks iff 'a' can be part of 'b'. Iterates over VALUE types!
  var marker = initIntSet()
  # watch out: parameters reversed because I'm too lazy to change the code...
  result = isPartOfAux(b, a, marker)

proc isPartOf*(a, b: PNode; flags: set[PartFlag] = {}): TAnalysisResult =
  ## Checks if location `a` can be part of location `b`: i.e. whether writing to
  ## `b` could affect what `a` reads. We treat seqs and strings as pointers
  ## because the code gen often just passes them as such.
  ##
  ## Note: `a` can only be part of `b`, if `a`'s type can be part of `b`'s
  ## type. Since however type analysis is more expensive, we perform it only
  ## if necessary.
  ##
  ## When `pfStructural` is set additional aliasing is detected:
  ## * a structural prefix of an accessor chain is considered part of it
  ##   (e.g. `x.f <| x.f.g`). Normally `x.f !<| x.f.g` because the
  ##   same-kind `nkDotExpr` comparison treats the differing field names as
  ##   siblings, but `pfStructural` walks the chain to recognise the
  ##   relationship.
  ## * Unrecognised node kinds are traversed recursively.
  ##
  ## When `pfBidirectional` is set:
  ## * In `nkObjConstr` the reverse direction `isPartOf(value, a)` is also
  ##   checked per field value so that reads hidden behind calls/closures
  ##   are detected.
  ##
  ## cases:
  ##
  ## YES-cases:
  ##  ```
  ##  x    <| x   # for general trees
  ##  x[]  <| x
  ##  x[i] <| x
  ##  x.f  <| x
  ##  x.f  <| x.f.g   # when pfStructural (prefix chain)
  ##  ```
  ##
  ## NO-cases:
  ## ```
  ## x           !<| y    # depending on type and symbol kind
  ## x[constA]   !<| x[constB]
  ## x.f         !<| x.g          # sibling fields at same level
  ## x.f         !<| y.f  iff x !<= y
  ## ```
  ##
  ## MAYBE-cases:
  ##
  ##  ```
  ##  x[] ?<| y[]   iff compatible type
  ##
  ##
  ##  x[]  ?<| y  depending on type
  ##  ```
  if a.isCompileTimeOnlyNode or b.isCompileTimeOnlyNode:
    return arNo

  if a.kind == b.kind:
    case a.kind
    of nkSym:
      const varKinds = {skVar, skTemp, skResult, skProc, skFunc}
      # same symbol: aliasing:
      if a.sym.id == b.sym.id: result = arYes
      elif a.sym.kind in varKinds or b.sym.kind in varKinds:
        # actually, a param could alias a var but we know that cannot happen
        # here. XXX make this more generic
        result = arNo
      else:
        # use expensive type check:
        if isPartOf(a.sym.typ, b.sym.typ) != arNo:
          result = arMaybe
        else:
          result = arNo
    of nkBracketExpr:
      result = isPartOf(a[0], b[0], flags)
      if a.len >= 2 and b.len >= 2:
        # array accesses:
        if result == arYes and isDeepConstExpr(a[1]) and isDeepConstExpr(b[1]):
          # we know it's the same array and we have 2 constant indexes;
          # if they are
          var x = if a[1].kind == nkHiddenStdConv: a[1][1] else: a[1]
          var y = if b[1].kind == nkHiddenStdConv: b[1][1] else: b[1]

          if sameValue(x, y): result = arYes
          elif pfStructural in flags and isAccessorPrefixOf(a, b):
            result = arYes
          else: result = arNo
        elif pfStructural in flags and isAccessorPrefixOf(a, b):
          result = arYes
        # else: maybe and no are accurate
      else:
        # pointer derefs:
        if result != arYes:
          if isPartOf(a.typ, b.typ) != arNo: result = arMaybe

    of nkDotExpr:
      result = isPartOf(a[0], b[0], flags)
      if result != arNo:
        # if the fields are different, it's not the same location
        if a[1].sym.id != b[1].sym.id:
          if pfStructural in flags and isAccessorPrefixOf(a, b):
            result = arYes
          else:
            result = arNo

    of nkHiddenDeref, nkDerefExpr:
      result = isPartOf(a[0], b[0], flags)
      # weaken because of indirection:
      if result != arYes:
        if isPartOf(a.typ, b.typ) != arNo: result = arMaybe

    of nkHiddenStdConv, nkHiddenSubConv, nkConv:
      result = isPartOf(a[1], b[1], flags)
    of nkObjUpConv, nkObjDownConv, nkCheckedFieldExpr:
      result = isPartOf(a[0], b[0], flags)
    else: result = arNo
    # Calls return a new location, so a default of ``arNo`` is fine.
  else:
    # go down recursively; this is quite demanding:
    const
      Ix0Kinds = {nkDotExpr, nkBracketExpr, nkObjUpConv, nkObjDownConv,
                  nkCheckedFieldExpr, nkHiddenAddr}
      Ix1Kinds = {nkHiddenStdConv, nkHiddenSubConv, nkConv}
      DerefKinds = {nkHiddenDeref, nkDerefExpr}
    case b.kind
    of Ix0Kinds:
      # a* !<| b.f  iff  a* !<| b
      result = isPartOf(a, b[0], flags)

    of DerefKinds:
      # a* !<| b[] iff
      result = arNo
      if isPartOf(a.typ, b.typ) != arNo:
        result = isPartOf(a, b[0], flags)
        if result == arNo: result = arMaybe

    of Ix1Kinds:
      # a* !<| T(b)  iff a* !<| b
      result = isPartOf(a, b[1], flags)

    of nkSym:
      # b is an atom, so we have to check a:
      case a.kind
      of Ix0Kinds:
        # a.f !<| b*  iff  a.f !<| b*
        result = isPartOf(a[0], b, flags)
      of Ix1Kinds:
        result = isPartOf(a[1], b, flags)

      of DerefKinds:
        if isPartOf(a.typ, b.typ) != arNo:
          result = isPartOf(a[0], b, flags)
          if result == arNo: result = arMaybe
        else:
          result = arNo
      else: result = arNo
    of nkObjConstr:
      result = arNo
      for i in 1..<b.len:
        let res = isPartOf(a, b[i][1], flags)
        if res != arNo:
          result = res
          if res == arYes: break
        if pfBidirectional in flags:
          let res2 = isPartOf(b[i][1], a, {pfStructural})
          if res2 != arNo:
            result = res2
            if res2 == arYes: break
    of nkCallKinds:
      result = arNo
      for i in 1..<b.len:
        # A call such as `fill(typeof(result.f))` has a compile-time-only
        # argument. It must not make the object constructor look aliased with
        # `result.f`; runtime arguments remain subject to the normal analysis.
        if b[i].isCompileTimeOnlyNode:
          continue
        let res = isPartOf(a, b[i], flags)
        if res != arNo:
          result = res
          if res == arYes: break
    of nkBracket:
      if b.len > 0:
        result = isPartOf(a, b[0], flags)
      else:
        result = arNo
    else:
      if pfStructural in flags:
        for i in 0..<b.safeLen:
          if isPartOf(a, b[i], flags) != arNo: return arMaybe
      result = arNo
