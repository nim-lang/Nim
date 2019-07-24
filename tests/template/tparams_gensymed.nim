discard """
output: '''
0
1
2
3
0
1
2
3
'''
"""
# bug #1915

import macros

# Test that parameters are properly gensym'ed finally:

template genNodeKind(kind, name: untyped) =
  proc name*(children: varargs[NimNode]): NimNode {.compiletime.}=
    result = newNimNode(kind)
    for c in children:
      result.add(c)

genNodeKind(nnkNone, None)


# Test that generics in templates still work (regression to fix #1915)

# bug #2004

type Something = object

proc testA(x: Something) = discard

template def(name: untyped) =
  proc testB[T](reallyUniqueName: T) =
    `test name`(reallyUniqueName)
def A

var x: Something
testB(x)


# bug #2215
# Test that templates in generics still work (regression to fix the
# regression...)

template forStatic(index, slice, predicate: untyped) =
  const a = slice.a
  const b = slice.b
  when a <= b:
    template iteration(i: int) =
      block:
        const index = i
        predicate
    template iterateStartingFrom(i: int) =
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

import tables

# bug #9476
proc getTypeInfo*(T: typedesc): pointer =
  var dummy: T
  getTypeInfo(dummy)


macro implementUnary(op: untyped): untyped =
  result = newStmtList()

  template defineTable(tableSymbol) =
    var tableSymbol = initTable[pointer, pointer]()
  let tableSymbol = genSym(nskVar, "registeredProcs")
  result.add(getAst(defineTable(tableSymbol)))

  template defineRegisterInstantiation(tableSym, regTemplSym, instSym, op) =
    template regTemplSym*(T: typedesc) =
      let ti = getTypeInfo(T)

      proc instSym(xOrig: int): int {.gensym, cdecl.} =
        let x {.inject.} = xOrig
        op

      tableSym[ti] = cast[pointer](instSym)

  let regTemplSymbol = ident("registerInstantiation")
  let instSymbol = ident("instantiation")
  result.add(getAst(defineRegisterInstantiation(
    tableSymbol, regTemplSymbol, instSymbol, op
  )))

  echo result.repr


implementUnary(): x*x

registerInstantiation(int)
registerInstantiation(float)

# bug #10192
template nest(body) {.dirty.} =
  template p1(b1: untyped) {.dirty, used.} =
    template implp1: untyped {.dirty.} = b1
  template p2(b2: untyped) {.dirty, used.} =
    template implp2: untyped {.dirty.} = b2

  body
  implp1
  implp2

template test() =
  nest:
    p1:
      var foo = "bar"
    p2:
      doAssert(foo.len == 3)

test()
