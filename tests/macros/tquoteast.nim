discard """
nimout: '''
true
5
5
3
'''
"""

import experimental/quote2

proc foo(arg1: int, arg2: string): string =
  "xxx"

macro foobar(arg: untyped): untyped =
  # simple generation of source code:
  #echo "foobar: ", arg.lispRepr
  result = quoteAst:
    echo "Hello world!"

  doAssert result[0].lispRepr == """(Command (Ident "echo") (StrLit "Hello world!"))"""

  # Explicit symbol binding. `quote do` would use `world`:
  let world = newLit("world")
  result = quoteAst(world):
    echo "Hello ", world, "!"

  doAssert result[0].lispRepr == """(Command (Ident "echo") (StrLit "Hello ") (StrLit "world") (StrLit "!"))"""

  # named argument
  result = quoteAst(world = newLit("world")):
    echo "Hello ", world, "!"

  doAssert result[0].lispRepr == """(Command (Ident "echo") (StrLit "Hello ") (StrLit "world") (StrLit "!"))"""

  # mixed usage
  let x = newLit(123)
  result = quoteAst(x, xyz = newLit("xyz"), arg):
    echo "abc ", x, " ", xyz, " ", arg

  # usage of bindSym
  result = quoteAst(foo = bindSym"foo"):
    echo foo(123, "abc")

  doAssert result[0].lispRepr == """(Command (Ident "echo") (Call (Sym "foo") (IntLit 123) (StrLit "abc")))"""

  result = quoteAst:
    var tmp = 1
    for x in 0 ..< 100:
      tmp *= 3

  doAssert result[0].lispRepr == """(VarSection (IdentDefs (Ident "tmp") (Empty) (IntLit 1)))"""

  # we don't actually want to generate code here in this test
  result = newEmptyNode()

let myVal = "Hallo Welt!"
foobar(myVal)

# example from #10326

proc skipNodes(arg: NimNode, kinds: set[NimNodeKind]): NimNode =
  result = arg
  while result.kind in kinds:
    result = result[0]

template id*(val: int) {.pragma.}
macro m1(): untyped =
   let x = newLit(10)
   let r1 = quote do:
     type T1 {.id(`x`).} = object

   let r2 = quoteAst(x):
     type T1 {.id(x).} = object

   let n1 = r1.skipNodes({nnkStmtList, nnkTypeSection, nnkTypeDef})[1][0][1]
   let n2 = r2.skipNodes({nnkStmtList, nnkTypeSection, nnkTypeDef})[1][0][1]
   doAssert n1.lispRepr == n2.lispRepr

m1()

macro lineinfoTest(): untyped =
  # line info is preserved as if the content of ``quoteAst`` is written in a template
  result = quoteAst:
    assert(false)

#lineinfoTest()

# example from #7375

macro fails(b: static[bool]): untyped =
  echo b
  result = newStmtList()

macro works(b: static[int]): untyped =
  echo b
  result = newStmtList()

macro foo(): untyped =
  var b = newLit(true)
  result = newStmtList()

  # Fails (not anymore)
  let tmp1 = quoteAst(b):
    fails(b)
  result.add tmp1

  # Works
  let tmp2 = quoteAst(b = newLit(123)):
    works(b)
  result.add tmp2

foo()

# example from #9745

var
  typ {.compiletime.} = newLit("struct ABC")
  name {.compiletime.} = ident("ABC")

macro abc(): untyped =
  # Inject the name of a type. This would not work with the originally
  # proposed ``uq(name)`` syntax, because a type section does not
  # allow a call expression here.
  result = quoteAst(name,typ):
    type
      name {.importc: typ.} = object

abc()

# example from #7889

# test.nim

from binder import bindme
bindme()

# example from #8220
import strformat

macro fooA(): untyped =
  result = quoteAst:
    let bar = "Hello, World"
    &"Let's interpolate {bar} in the string"

doAssert fooA() == "Let's interpolate Hello, World in the string"

# example from #7589

macro fooB(): untyped =
  # test for backticked symbol.
  result = quoteAst(`==` = bindSym"=="):
    echo 3 == 4
  doAssert result[0][1][0].kind == nnkClosedSymChoice

fooB()

# example from #7726

import macros

macro fooC(): untyped =
  let a = @[1, 2, 3, 4, 5]
  result = quoteAst(len = newLit(a.len)):
    len

macro fooD(): untyped =
  let a = @[1, 2, 3, 4, 5]
  let len = a.len
  result = quoteAst(len = newLit(len)):
    len

macro fooE(): untyped =
  let a = @[1, 2, 3, 4, 5]
  result = quoteAst(x = newLit(a[2])):
    x

echo fooC() # Outputs 5
echo fooD() # Outputs 5
echo fooE() # Outputs 3

# example from #10430

import macros

macro commentTest(arg: untyped): untyped =
  let tmp = quoteAst:
    ## comment 1
    echo "abc"
    ## comment 2
    ## still comment 2

  doAssert tmp.treeRepr == arg.treeRepr

commentTest:
  ## comment 1
  echo "abc"
  ## comment 2
  ## still comment 2
