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
  echo ""
  echo "tupleNewLitTests"
  type
    EmptyT = tuple
  proc emptyT() : EmptyT =
    discard
  macro t0() : untyped =
    result = newLit(emptyT())
  macro t1() : untyped =
    result = newLit((5,))
  macro t2() : untyped =
    result = newLit((a:5))
  macro t3() : untyped =
    result = newLit((5,"5"))
  macro t4() : untyped =
    result = newLit((a:5,b:"5"))
  macro t5() : untyped =
    result = newLit(@[(5,)])
  macro t6() : untyped =
    result = newLit(@[(a:5)])
  macro t7() : untyped =
    result = newLit(@[(5,"5")])
  macro t8() : untyped =
    result = newLit(@[(a:5,b:"5")])
  macro t9() : untyped =
    result = newLit(@[(a:(5,6),b:emptyT())])
  const
    eT = emptyT()
    x0 = t0()
    x1 = t1()
    x2 = t2()
    x3 = t3()
    x4 = t4()
    x5 = t5()
    x6 = t6()
    x7 = t7()
    x8 = t8()
    x9 = t9()
  doAssert(x0 == eT)
  echo x0
  doAssert(x1 == (5,))
  echo x1
  doAssert(x2 == (a:5))
  echo x2
  doAssert(x3 == (5,"5"))
  echo x3
  doAssert(x4 == (a:5,b:"5"))
  echo x4
  doAssert(x5 == @[(5,)])
  echo x5
  doAssert(x6 == @[(a:5)])
  echo x6
  doAssert(x7 == @[(5,"5")])
  echo x7
  doAssert(x8 == @[(a:5,b:"5")])
  echo x8
  doAssert(x9 == @[(a:(5,6),b:eT)])
  echo x9

  echo "tupleNewLitTests ok"
  echo ""
