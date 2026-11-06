discard """
action: reject
errormsg: "node has no type"
"""

# bug #13384

import macros

static:
  var arg: NimNode = nil
  echo arg.treeRepr
  echo arg.getType.treeRepr
  echo arg.getTypeInst.treeRepr
  echo arg.getTypeImpl.treeRepr
