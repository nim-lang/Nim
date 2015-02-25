
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


# bug #2215
# Test that templates in generics still work (regression to fix the
# regression...)

template forStatic(index: expr, slice: Slice[int], predicate: stmt):
                   stmt {.immediate.} =
  const a = slice.a
  const b = slice.b
  when a <= b:
    template iteration(i: int) =
      block:
        const index = i
        predicate
    template iterateStartingFrom(i: int): stmt =
      when i <= b:
        iteration i
        iterateStartingFrom i + 1
    iterateStartingFrom a

proc concreteProc(x: int) =
  forStatic i, 0..3:
    echo i

proc genericProc(x: any) =
  forStatic i, 0..3:
    echo i

concreteProc(7) # This works
genericProc(7)  # This doesn't compile
