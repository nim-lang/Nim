discard """
  cmd: "nim c --mm:yrc -d:useMalloc --threads:on $file"
  output: "ok"
  disabled: "windows"
  disabled: "freebsd"
  disabled: "openbsd"
"""

# Deterministic port of dumpster's `fuzz` test
# (https://claytonwramsey.com/blog/dumpster/): drive a mutable object graph
# through a long random sequence of node/edge inserts and removals, then drop
# every root and assert that *every allocation ever made is destroyed exactly
# once* -- no leak (count 0) and no double free (count > 1). The graph grows
# thick with overlapping and self cycles, so only the cycle collector can wind
# it down. A fixed LCG seed makes the shape reproducible across runs.

type
  DropCount = object
    id: int
    live: bool          # false in any moved-from temporary -> never miscounts
  Node = ref object
    refs: seq[Node]
    dc: DropCount

var counts: seq[int]    # counts[id] == times allocation `id` was destroyed

proc `=destroy`(x: DropCount) =
  if x.live: inc counts[x.id]

var nextId = 0
proc newNode(): Node =
  counts.add 0
  result = Node(refs: @[], dc: DropCount(id: nextId, live: true))
  inc nextId

# `child` is a by-value borrow (dumpster's `Gc::clone`): storing it copies the
# reference, leaving the caller's root slot still owning. Using `.refs.add`
# directly would move the root at its last read and change the graph shape.
proc link(parent, child: Node) = parent.refs.add child

# Small fixed-seed LCG (Numerical Recipes constants) for reproducible shape.
var rngState: uint32 = 12345
proc rnd(n: int): int =
  rngState = rngState * 1664525'u32 + 1013904223'u32
  int((rngState shr 16) mod uint32(n))

proc run =
  const N = 20_000
  var roots: seq[Node]
  for i in 0 ..< 50: roots.add newNode()

  for _ in 0 ..< N:
    if roots.len == 0: roots.add newNode()
    case rnd(4)
    of 0:                                   # allocate a fresh root
      roots.add newNode()
    of 1:                                   # add edge from -> to (may self-loop)
      let a = rnd(roots.len)
      let b = rnd(roots.len)
      link(roots[a], roots[b])
    of 2:                                   # drop a root handle (swap-remove)
      let i = rnd(roots.len)
      roots[i] = roots[roots.high]
      roots.setLen roots.len - 1
    else:                                   # drop one outgoing edge of a root
      let a = rnd(roots.len)
      if roots[a].refs.len > 0:
        let j = rnd(roots[a].refs.len)
        roots[a].refs[j] = roots[a].refs[roots[a].refs.high]
        roots[a].refs.setLen roots[a].refs.len - 1

  roots.setLen 0                            # release every remaining root
  GC_fullCollect()
  GC_fullCollect()

run()

var missing = 0
for id in 0 ..< nextId:
  if counts[id] != 1:
    inc missing
doAssert missing == 0, "graph not fully reclaimed: " & $missing & " of " &
  $nextId & " allocations leaked or double-freed"
echo "ok"
