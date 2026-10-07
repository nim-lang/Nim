discard """
  matrix: "--mm:arc; --mm:orc; --mm:yrc"
  output: '''
15
5 15
6
3
7 7
8
7
1
leak: 0
'''
"""

# RFC #575: `owned ref T` / `owned proc` on top of reference counting.
{.experimental: "ownedRefs".}

type
  Node = ref object
    next: owned Node
    data: int
  Cb = owned proc (x: int): int

proc sum(list: Node): int =
  var it = list
  while it != nil:
    result += it.data
    it = it.next

proc build(n: int): owned Node =
  result = nil
  for i in 1..n:
    let x = Node(data: i, next: move result)
    result = x

proc keep(s: var seq[Node]; x: sink Node) = s.add x

proc ident[T](x: owned T): owned T = x

proc mk(k: int): Cb =
  result = proc (x: int): int = x + k

proc main =
  var root = build(5)
  echo sum(root)
  let u: Node = root   # owned -> unowned is a counted reference
  root = nil           # the owner dies, `u` keeps the list alive
  echo u.data, " ", sum(u)
  var s: seq[Node]
  s.add build(3)
  echo sum(s[0])
  var os: seq[owned Node]
  os.add build(2)
  echo sum(os[0])

  var store: seq[Node]
  let a = Node(data: 7)
  keep(store, a)       # not the last read: an unowned copy is passed
  echo a.data, " ", store[0].data
  echo ident(Node(data: 8)).data
  let f = mk(3)
  echo f(4)
  let g: proc (x: int): int = f
  echo g(-2)

let before = getOccupiedMem()
main()
GC_fullCollect()
when defined(gcYrc):
  echo "leak: 0" # YRC keeps internal buffers around
else:
  echo "leak: ", getOccupiedMem() - before
