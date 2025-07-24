#
#
#           The Nim Compiler
#        (c) Copyright 2022 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## New "strict funcs" checking. Much simpler and hopefully easier to teach than
## the old but more advanced algorithm that can/could be found in `varpartitions.nim`.

import ast, typeallowed, renderer
from aliasanalysis import PathKinds0, PathKinds1
from trees import getMagic

proc isDangerousLocation*(n: PNode; owner: PSym): bool =
  var n = n
  var hasDeref = false
  while true:
    case n.kind
    of nkDerefExpr, nkHiddenDeref:
      if n[0].typ.kind != tyVar:
        hasDeref = true
      n = n[0]
    of PathKinds0 - {nkDerefExpr, nkHiddenDeref}:
      n = n[0]
    of PathKinds1:
      n = n[1]
    of nkCallKinds:
      if n.len > 1:
        if (n.typ != nil and classifyViewType(n.typ) != noView) or getMagic(n) == mSlice:
          # borrow from first parameter:
          n = n[1]
        else:
          break
      else:
        break
    else:
      break
  if n.kind == nkSym:
    # dangerous if contains a pointer deref or if it doesn't belong to us:
    result = hasDeref or n.sym.owner != owner
    when false:
      # store to something that belongs to a `var` parameter is fine:
      let s = n.sym
      if s.kind == skParam:
        # dangerous unless a `var T` parameter:
        result = s.typ.kind != tyVar
      else:
        # dangerous if contains a pointer deref or if it doesn't belong to us:
        result = hasDeref or s.owner != owner
  else:
    # dangerous if it contains a pointer deref
    result = hasDeref
