
# bug #1944
import macros

template t(e: expr): stmt =
  macro m(eNode: expr): stmt =
    echo eNode.treeRepr
  m e

t 5
