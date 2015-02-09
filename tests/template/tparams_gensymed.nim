
# bug #1915

import macros

# Test that parameters are properly gensym'ed finally:

template genNodeKind(kind, name: expr): stmt =
  proc name*(children: varargs[PNimrodNode]): PNimrodNode {.compiletime.}=
    result = newNimNode(kind)
    for c in children:
      result.add(c)

genNodeKind(nnkNone, None)


# Test that generics in templates still work (regression to fix #1915)

# bug #2004

type Something = object

proc testA(x: Something) = discard

template def(name: expr) {.immediate.} =
  proc testB[T](reallyUniqueName: T) =
    `test name`(reallyUniqueName)
def A

var x: Something
testB(x)


