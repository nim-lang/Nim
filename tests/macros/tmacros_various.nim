discard """
  nimout: '''
Infix
  Ident "=>"
  Call
    Ident "name"
    Ident "a"
    ExprColonExpr
      Ident "b"
      Ident "cint"
  NilLit
macrocache ok
'''

  output: '''
x = 10
x + y = 30
proc foo[T, N: static[int]]()
proc foo[T; N: static[int]]()
a[0]: 42
a[1]: 45
x: some string
([("key", "val"), ("keyB", "2")], [("val", "key"), ("2", "keyB")])
([("key", "val"), ("keyB", "2")], [("val", "key"), ("2", "keyB")])
0
0
0
'''
"""


import macros, sugar, macrocache


block tdump:
  let
    x = 10
    y = 20
  dump x
  dump(x + y)


block texprcolonexpr:
  macro def(x): untyped =
    echo treeRepr(x)

  def name(a, b:cint) => nil



block tgenericparams:
  macro test():string =
    let expr0 = "proc foo[T, N: static[int]]()"
    let expr1 = "proc foo[T; N: static[int]]()"

    newLit($toStrLit(parseExpr(expr0)) & "\n" & $toStrLit(parseExpr(expr1)))

  echo test()



block tidgen:
  # Test compile-time state in same module
  var gid {.compileTime.} = 3

  macro genId(): int =
    result = newIntLitNode(gid)
    inc gid

  proc Id1(): int {.compileTime.} = return genId()
  proc Id2(): int {.compileTime.} = return genId()

  doAssert Id1() == 3
  doAssert Id2() == 4



block tlexerex:
  macro match(s: cstring|string; pos: int; sections: varargs[untyped]): untyped =
    for sec in sections:
      expectKind sec, nnkOfBranch
      expectLen sec, 2
    result = newStmtList()

  var input = "the input"
  var pos = 0
  match input, pos:
  of r"[a-zA-Z_]\w+": echo "an identifier"
  of r"\d+": echo "an integer"
  of r".": echo "something else"



block tcopylineinfo:
  # issue #5617, feature request
  type Test = object

  macro mixer(n: typed): untyped =
    let x = newIdentNode("echo")
    x.copyLineInfo(n)
    result = newLit(x.lineInfo == n.lineInfo)

  var z = mixer(Test)
  doAssert z

block tsetgetlineinfo:
  # issue #21098, feature request
  type Test = object

  macro mixer1(n: typed): untyped =
    let x = newIdentNode("echo")
    var lineInfo = n.lineInfoObj
    x.setLineInfo lineInfo
    result = newLit(x.lineInfo == n.lineInfo)

  macro mixer2(n: typed): untyped =
    let x = newIdentNode("echo")
    var lineInfo = n.lineInfoObj
    lineInfo.line += 1
    x.setLineInfo lineInfo
    result = newLit(x.lineInfo != n.lineInfo)

  doAssert mixer1(Test)

  doAssert mixer2(Test)



block tdebugstmt:
  macro debug(n: varargs[untyped]): untyped =
    result = newNimNode(nnkStmtList, n)
    for i in 0..n.len-1:
      add(result, newCall("write", newIdentNode("stdout"), toStrLit(n[i])))
      add(result, newCall("write", newIdentNode("stdout"), newStrLitNode(": ")))
      add(result, newCall("writeLine", newIdentNode("stdout"), n[i]))

  var
    a: array[0..10, int]
    x = "some string"
  a[0] = 42
  a[1] = 45

  debug(a[0], a[1], x)

const
  pairs = {"key": "val", "keyB": "2"}

macro bilookups(arg: static[openArray[(string, string)]]): untyped =
  var a = newTree(nnkBracket)
  var b = newTree(nnkBracket)
  for (k, v) in items(arg):
    a.add(newTree(nnkTupleConstr, newLit k, newLit v))
    b.add(newTree(nnkTupleConstr, newLit v, newLit k))
  result = newTree(nnkTupleConstr, a, b)

macro bilookups2(arg: untyped): untyped =
  var a = newTree(nnkBracket)
  var b = newTree(nnkBracket)
  arg.expectKind(nnkTableConstr)
  for x in items(arg):
    x.expectKind(nnkExprColonExpr)
    a.add(newTree(nnkTupleConstr, x[0], x[1]))
    b.add(newTree(nnkTupleConstr, x[1], x[0]))
  result = newTree(nnkTupleConstr, a, b)

const cnst1 = bilookups(pairs)
echo cnst1
const cnst2 = bilookups2({"key": "val", "keyB": "2"})
echo cnst2



# macrocache #11404
const
  mcTable = CacheTable"nimTest"
  mcSeq = CacheSeq"nimTest"
  mcCounter = CacheCounter"nimTest"

static:
  doAssert(mcCounter.value == 0) # CacheCounter.value
  mcCounter.inc                  # CacheCounter.inc
  doAssert(mcCounter.value == 1) # CacheCounter.value

  let a = newLit(1)
  let b = newLit(2)
  let c = newLit(3)
  let d = newLit(4)

  mcSeq.add a # CacheSeq.add
  mcSeq.add b # CacheSeq.add
  mcSeq.add c # CacheSeq.add

  doAssert(mcSeq.len == 3)  # CacheSeq.len
  #doAssert(c in mcSeq)      # CacheSeq.contains
  #doAssert(d notin mcSeq)   # CacheSeq.contains

  mcSeq.incl d              # CacheSeq.incl
  doAssert(mcSeq.len == 4)  # CacheSeq.len

  mcSeq.incl c              # CacheSeq.incl
  doAssert(mcSeq.len == 4)  # CacheSeq.len

  doAssert(mcSeq[3] == d)   # CacheSeq.[]

  #doAssert(mcSeq.pop() == d)# CacheSeq.pop
  #doAssert(mcSeq.len == 3)  # CacheSeq.len

  doAssert(mcTable.len == 0)  # CacheTable.len
  mcTable["a"] = a            # CacheTable.[]=
  doAssert(mcTable.len == 1)  # CacheTable.len

  doAssert(mcTable["a"] == a) # CacheTable.[]
  #doAssert("a" in mcTable)    # CacheTable.contains
  #doAssert(mcTable.hasKey("a"))# CacheTable.hasKey

  for k, v in mcTable:  # CacheTable.items
    doAssert(k == "a")
    doAssert(v == a)

  echo "macrocache ok"

block tupleNewLitTests:
  macro t(): untyped =
    result = newLit (1, "foo", (), (1,), (a1: 'x', a2: @["ba"]))
  doAssert $t() == """(1, "foo", (), (1,), (a1: 'x', a2: @["ba"]))"""
    # this `$` test is needed because tuple equality doesn't distinguish
    # between named vs unnamed tuples
  doAssert t() == (1, "foo", (), (1, ), (a1: 'x', a2: @["ba"]))

from strutils import contains
block getImplTransformed:
  macro bar(a: typed): string =
    # newLit a.getImpl.repr # this would be before code transformation
    let b = a.getImplTransformed
    newLit b.repr
  template toExpand() =
    for ai in 0..2: echo ai
  proc baz(a=1): int =
    defer: discard
    toExpand()
    12
  const code = bar(baz)
  # sanity check:
  doAssert "finally" in code # `defer` is lowered to try/finally
  doAssert "while" in code # `for` is lowered to `while`
  doAssert "toExpand" notin code
    # template is expanded (but that would already be the case with
    # `a.getImpl.repr`, unlike the other transformations mentioned above


# test macro resemming
macro makeVar(): untyped =
  quote:
    var tensorY {.inject.}: int

macro noop(a: typed): untyped =
  a

noop:
  makeVar
echo tensorY

macro xbenchmark(body: typed): untyped =
  result = body

xbenchmark:
  proc fastSHA(inputtest: string) =
    discard inputtest
  fastSHA("hey")


block: # bug #13511
  type
    Builder = ref object
      components: seq[Component]
    Component = object

  proc add(builder: var Builder, component: Component) {.compileTime.} =
    builder.components.add(component)

  macro debugAst(arg: typed): untyped =
    ## just for debugging purpose.
    discard arg.treeRepr
    return arg

  static:
    var component = Component()
    var builder = Builder()

    template foo(): untyped =
      ## WAS: this doc comment causes compilation failure.
      builder

    debugAst:
      add(foo(), component)

block: # bug #15118
  macro flop(name: static string) =
    let id = genSym(nskType, "env")
    let r =
      nnkStmtList.newTree(
        nnkTypeSection.newTree(
          nnkTypeDef.newTree(
            id,
            newEmptyNode(),
            nnkRefTy.newTree(
              nnkObjectTy.newTree(
                newEmptyNode(),
                newEmptyNode(),
                nnkRecList.newTree(
                  nnkIdentDefs.newTree(
                    newIdentNode(name),
                    newIdentNode("int"),
                    newEmptyNode()
                  )
                )
              ) 
            )
          )
        ),

        # var f: T
  
        nnkVarSection.newTree(
          nnkIdentDefs.newTree(
            newIdentNode("f"),
            id,
            newEmptyNode()
          )
        ),

        # echo f.a
        nnkCommand.newTree(
          newIdentNode("new"),
          newIdentNode("f")
        ),

        nnkCommand.newTree(
          newIdentNode("echo"),
          nnkDotExpr.newTree(
            newIdentNode("f"),
            newIdentNode(name)
          )
        )
      )
    r


  block:
    flop("a")

  block:
    flop("b")
