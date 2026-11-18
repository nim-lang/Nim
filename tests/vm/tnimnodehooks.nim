discard """
  matrix: "--mm:orc; --mm:refc"
  output: '''
a
b
19
18
17
16
15
42 2
7
"ins"
echo(2)
echo(1)
11
c
19
18
17
16
15
42 1
7
"ins"
echo(2)
echo(1)
11
echo "a"
echo "b"
echo "c"
1
50000 + y
100000 + y
'''
"""

# bug #26476: the VM counts the references to NimNodes and frees them. These
# are the ways a NimNode can be copied, moved and destroyed in a macro.

import std/[macros, tables, sequtils, strutils]

type
  Ctx = ref object
    nodes: seq[NimNode]
    byName: Table[string, NimNode]
    last: NimNode
  Pair = object
    a, b: NimNode
    name: string

var ctGlobal {.compileTime.}: seq[NimNode]
var ctTab {.compileTime.}: Table[string, NimNode]

proc mk(i: int): NimNode = newCall(ident"echo", newLit(i))

proc collect(n: NimNode): seq[NimNode] =
  for c in n: result.add c

macro gen(body: untyped): untyped =
  let ctx = Ctx()
  for i in 0..<20:
    let x = mk(i)
    ctx.nodes.add x
    ctx.byName["n" & $i] = x
    ctx.last = x
  var p = Pair(a: ctx.last, b: ctx.nodes[0], name: "p")
  var q = p
  q.a = newLit("changed")
  doAssert p.a.kind == nnkCall
  let cl = proc (k: int): NimNode = ctx.nodes[k]
  doAssert cl(3)[1].intVal == 3
  try:
    let bad = ctx.byName["nope"]
    discard bad
  except KeyError:
    discard
  ctGlobal.add body
  ctTab["body"] = body
  let kids = collect(body)
  doAssert kids.len == body.len
  let mapped = kids.mapIt(it.copyNimTree)
  result = newStmtList()
  for m in mapped: result.add m
  for i in countdown(ctx.nodes.high, 15): result.add ctx.nodes[i]
  let v = 42
  let blen = body.len
  result.add quote do:
    echo `v`, " ", `blen`
  result.add ctx.byName["n7"]
  var s2 = ctx.nodes
  s2.setLen 3
  s2.del 0
  s2.insert(newLit("ins"), 0)
  for x in s2: result.add newCall(ident"echo", x.toStrLit)
  var arr: array[3, NimNode]
  arr[0] = newLit(1); arr[1] = arr[0]; arr[2] = move arr[1]
  result.add newCall(ident"echo", arr[2], arr[0])

macro useGlobal(): untyped =
  result = newStmtList()
  for b in ctGlobal: result.add newCall(ident"echo", newLit(b.repr.strip))
  result.add newCall(ident"echo", newLit(ctTab["body"].len))

gen:
  echo "a"
  echo "b"
gen:
  echo "c"
useGlobal()

template tmpl(a, b: untyped): untyped = a + b

macro viaGetAst(): untyped =
  # the NimNodes passed to `getAst` are freed too:
  var s = newStmtList()
  for i in 0..<120_000:
    let x = getAst(tmpl(newLit(i), newIdentNode("y")))
    if i mod 50_000 == 0 and i > 0: s.add newCall(ident"echo", newLit(x.repr))
  result = s

viaGetAst()

macro m(): untyped =
  var n = newStmtList()
  for i in 0..<1000: n.add newEmptyNode()
  result = newLit(n.len)

static:
  for i in 0 ..< 1_000_000:
    discard newEmptyNode()

for i in 0..<3:
  doAssert m() == 1000
