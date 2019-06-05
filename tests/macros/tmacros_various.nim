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
'''
"""


import macros, sugar


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



block tlineinfo:
  # issue #5617, feature request
  type Test = object

  macro mixer(n: typed): untyped =
    let x = newIdentNode("echo")
    x.copyLineInfo(n)
    result = newLit(x.lineInfo == n.lineInfo)

  var z = mixer(Test)
  doAssert z



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
