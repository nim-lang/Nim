discard """
  targets: "c cpp"
  matrix: "--mm:orc; --mm:refc"
  output: '''
i0:2i0
i01:2i01
n 2 y1
i0:2i0
i01:2i01
n 2 y1
mid
p-p0+3
mid
p-p0p1+3
p 2 p-p0p1
r1-r10
r1-r10r11
mid
r10+r11
r1 2 r1-r10r11
r2-r20
r2-r20r21
mid
r20+r21
r2 2 r2-r20r21
'''
"""

# Refs #24662. Closure iterators whose environment holds a seq, a string, refs
# and a type with a destructor, the environment of a nested iterator living in
# a field of the outer one. Under ARC/ORC every environment, including the
# nested one, must be destroyed (this is only checked there: refc has no
# destructors). A `yield` inside an expression keeps a string temporary alive
# across the suspension.

type
  Node = ref object
    name: string
    kids: seq[Node]
  Tracked = object
    id: int

var destroyed = 0

proc `=destroy`(t: var Tracked) =
  if t.id != 0: inc destroyed
proc `=copy`(a: var Tracked, b: Tracked) {.error.}

template expectDestroyed(n: int) =
  when defined(gcArc) or defined(gcOrc):
    GC_fullCollect()
    doAssert destroyed == n, "destroyed " & $destroyed & ", expected " & $n

template yieldThen(v: string, e: untyped): untyped =
  yield v
  e

# The nested iterator captures nothing of the outer one.
iterator outerA(): string {.closure.} =
  let keep = Tracked(id: 1)
  var names = @["x", "y"]
  var node = Node(name: "n")
  iterator inner(): string {.closure.} =
    let innerKeep = Tracked(id: 2)
    var local = "i"
    var kids: seq[Node]
    for i in 0 ..< 2:
      local.add $i
      kids.add Node(name: local)
      yield local & ":" & $innerKeep.id & kids[^1].name
  let it = inner
  for s in it():
    yield s
  for s in names:
    node.kids.add Node(name: s & $keep.id)
  yield node.name & " " & $node.kids.len & " " & node.kids[1].name

proc runA() =
  for s in outerA():
    echo s

runA()
expectDestroyed(2)
runA()
expectDestroyed(4)

# The nested iterator captures variables of the proc that declares it.
proc withCapture(tag: string) =
  let keep = Tracked(id: 1)
  var names = @[tag & "0", tag & "1"]
  var node = Node(name: tag)
  iterator inner(): string {.closure.} =
    let innerKeep = Tracked(id: 2)
    var local = tag & "-"
    for s in names:
      local.add s
      node.kids.add Node(name: local)
      let r = local & "+" & yieldThen("mid", $(keep.id + innerKeep.id))
      yield r
  let it = inner
  for s in it():
    echo s
  echo node.name, " ", node.kids.len, " ", node.kids[1].name

withCapture("p")
expectDestroyed(6)

# The nested iterator captures variables of the iterator that declares it.
# The two environments reference each other; only their values are checked.
var runs = 0
iterator outerB(): string {.closure.} =
  inc runs
  let tag = "r" & $runs
  var names = @[tag & "0", tag & "1"]
  var node = Node(name: tag)
  iterator inner(): string {.closure.} =
    var local = tag & "-"
    for s in names:
      local.add s
      node.kids.add Node(name: local)
      yield local
  let it = inner
  for s in it():
    yield s
  let r = names[0] & "+" & yieldThen("mid", names[1])
  yield r
  yield node.name & " " & $node.kids.len & " " & node.kids[1].name

for round in 0 ..< 2:
  for s in outerB():
    echo s
