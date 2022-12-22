
import ast

import std / assertions

const
  PathKinds0* = {nkDotExpr, nkCheckedFieldExpr,
                 nkBracketExpr, nkDerefExpr, nkHiddenDeref,
                 nkAddr, nkHiddenAddr,
                 nkObjDownConv, nkObjUpConv}
  PathKinds1* = {nkHiddenStdConv, nkHiddenSubConv}

proc skipConvDfa*(n: PNode): PNode =
  result = n
  while true:
    case result.kind
    of nkObjDownConv, nkObjUpConv:
      result = result[0]
    of PathKinds1:
      result = result[1]
    else: break

proc isAnalysableFieldAccess*(orig: PNode; owner: PSym): bool =
  var n = orig
  while true:
    case n.kind
    of PathKinds0 - {nkHiddenDeref, nkDerefExpr}:
      n = n[0]
    of PathKinds1:
      n = n[1]
    of nkHiddenDeref, nkDerefExpr:
      # We "own" sinkparam[].loc but not ourVar[].location as it is a nasty
      # pointer indirection.
      # bug #14159, we cannot reason about sinkParam[].location as it can
      # still be shared for tyRef.
      n = n[0]
      return n.kind == nkSym and n.sym.owner == owner and
         (n.sym.typ.skipTypes(abstractInst-{tyOwned}).kind in {tyOwned})
    else: break
  # XXX Allow closure deref operations here if we know
  # the owner controlled the closure allocation?
  result = n.kind == nkSym and n.sym.owner == owner and
    {sfGlobal, sfThread, sfCursor} * n.sym.flags == {} and
    (n.sym.kind != skParam or isSinkParam(n.sym)) # or n.sym.typ.kind == tyVar)
  # Note: There is a different move analyzer possible that checks for
  # consume(param.key); param.key = newValue  for all paths. Then code like
  #
  #   let splited = split(move self.root, x)
  #   self.root = merge(splited.lower, splited.greater)
  #
  # could be written without the ``move self.root``. However, this would be
  # wrong! Then the write barrier for the ``self.root`` assignment would
  # free the old data and all is lost! Lesson: Don't be too smart, trust the
  # lower level C++ optimizer to specialize this code.

type AliasKind* = enum
  yes, no, maybe

proc aliases*(obj, field: PNode): AliasKind =
  # obj -> field:
  # x -> x: true
  # x -> x.f: true
  # x.f -> x: false
  # x.f -> x.f: true
  # x.f -> x.v: false
  # x -> x[]: true
  # x[] -> x: false
  # x -> x[0]: true
  # x[0] -> x: false
  # x[0] -> x[0]: true
  # x[0] -> x[1]: false
  # x -> x[i]: true
  # x[i] -> x: false
  # x[i] -> x[i]: maybe; Further analysis could make this return true when i is a runtime-constant
  # x[i] -> x[j]: maybe; also returns maybe if only one of i or j is a compiletime-constant
  template collectImportantNodes(result, n) =
    var result: seq[PNode]
    var n = n
    while true:
      case n.kind
      of PathKinds0 - {nkDotExpr, nkBracketExpr, nkDerefExpr, nkHiddenDeref}:
        n = n[0]
      of PathKinds1:
        n = n[1]
      of nkDotExpr, nkBracketExpr, nkDerefExpr, nkHiddenDeref:
        result.add n
        n = n[0]
      of nkSym:
        result.add n
        break
      else: return no

  collectImportantNodes(objImportantNodes, obj)
  collectImportantNodes(fieldImportantNodes, field)

  # If field is less nested than obj, then it cannot be part of/aliased by obj
  if fieldImportantNodes.len < objImportantNodes.len: return no

  result = yes
  for i in 1..objImportantNodes.len:
    # We compare the nodes leading to the location of obj and field
    # with each other.
    # We continue until they diverge, in which case we return no, or
    # until we reach the location of obj, in which case we do not need
    # to look further, since field must be part of/aliased by obj now.
    # If we encounter an element access using an index which is a runtime value,
    # we simply return maybe instead of yes; should further nodes not diverge.
    let currFieldPath = fieldImportantNodes[^i]
    let currObjPath = objImportantNodes[^i]

    if currFieldPath.kind != currObjPath.kind:
      return no

    case currFieldPath.kind
    of nkSym:
      if currFieldPath.sym != currObjPath.sym: return no
    of nkDotExpr:
      if currFieldPath[1].sym != currObjPath[1].sym: return no
    of nkDerefExpr, nkHiddenDeref:
      discard
    of nkBracketExpr:
      if currFieldPath[1].kind in nkLiterals and currObjPath[1].kind in nkLiterals:
        if currFieldPath[1].intVal != currObjPath[1].intVal:
          return no
      else:
        result = maybe
    else: assert false # unreachable

