discard """
  cmd: "nim c --mm:yrc -d:useMalloc --threads:on $file"
  output: "ok"
  valgrind: "leaks"
  disabled: "windows"
  disabled: "freebsd"
  disabled: "openbsd"
"""

# Functional test for the Tarjan-based collector: doubly-linked dead rings,
# self-referential cells, and one surviving ring whose integrity is checked
# after a full collect.

type
  Node = ref object
    next: Node
    prev: Node
    data: string

proc makeRing(n: int): Node =
  result = Node(data: "head")
  var cur = result
  for i in 1 ..< n:
    let x = Node(data: $i)
    cur.next = x
    x.prev = cur
    cur = x
  cur.next = result
  result.prev = cur

proc dropRings =
  for i in 0 ..< 2000:
    discard makeRing(10)   # dead immediately

proc keepOne: Node =
  for i in 0 ..< 100:
    discard makeRing(5)
  result = makeRing(7)     # survives

proc selfRef =
  type S = ref object
    self: S
    buf: seq[int]
  for i in 0 ..< 500:
    let s = S(buf: newSeq[int](8))
    s.self = s

dropRings()
selfRef()
let keep = keepOne()
GC_fullCollect()
doAssert keep.data == "head"
var cnt = 0
var it = keep
while true:
  inc cnt
  it = it.next
  if it == keep: break
doAssert cnt == 7, "live ring corrupted: " & $cnt
echo "ok"
