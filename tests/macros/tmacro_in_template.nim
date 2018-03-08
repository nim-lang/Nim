
# bug #1944
import macros

template t(e: untyped): untyped =
  macro m(eNode: untyped): untyped =
    echo eNode.treeRepr
  m e

t 5
