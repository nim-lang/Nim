
# bug #1915

import macros

# Test that parameters are properly gensym'ed finally:

template genNodeKind(kind, name: expr): stmt =
  proc name*(children: varargs[PNimrodNode]): PNimrodNode {.compiletime.}=
    result = newNimNode(kind)
    for c in children:
      result.add(c)

genNodeKind(nnkNone, None)
