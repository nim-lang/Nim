
import ast

const
  PathKinds0* = {nkDotExpr, nkCheckedFieldExpr,
                 nkBracketExpr, nkDerefExpr, nkHiddenDeref,
                 nkAddr, nkHiddenAddr,
                 nkObjDownConv, nkObjUpConv}
  PathKinds1* = {nkHiddenStdConv, nkHiddenSubConv}

type AliasKind* = enum
  yes, no, maybe

proc aliases*(obj, field: PNode): AliasKind =
  # obj -> field:
  # x -> x: true
  # x -> x.f: true
  # x.f -> x: false
  # x.f -> x.f: true
  # x.f -> x.v: false
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
      of PathKinds0 - {nkDotExpr, nkBracketExpr}:
        n = n[0]
      of PathKinds1:
        n = n[1]
      of nkDotExpr, nkBracketExpr:
        result.add n
        n = n[0]
      of nkSym:
        result.add n; break
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
    of nkBracketExpr:
      if currFieldPath[1].kind in nkLiterals and currObjPath[1].kind in nkLiterals:
        if currFieldPath[1].intVal != currObjPath[1].intVal:
          return no
      else:
        result = maybe
    else: assert false # unreachable

