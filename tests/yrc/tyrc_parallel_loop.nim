discard """
  cmd: "nim c --mm:yrc -d:useMalloc --threads:on $file"
  output: "ok"
  valgrind: "leaks"
  disabled: "windows"
  disabled: "freebsd"
  disabled: "openbsd"
"""

# The "parallel_loop" complex graph from Clayton Ramsey's `dumpster` collector
# (https://claytonwramsey.com/blog/dumpster/). Four allocations form a single
# SCC built from two *overlapping* cycles that share nodes 1 and 4:
#
#     1 -> 4        4 -> 2, 4 -> 3        2 -> 1, 3 -> 1
#
# so 1->4->2->1 and 1->4->3->1 traverse the same 1 and 4. Every node keeps a
# nonzero refcount from *inside* the SCC, so plain reference counting can never
# free any of them; only cycle collection can, and only once the last external
# handle is gone. We drop the four root handles one at a time and assert that
# nothing is reclaimed until the final drop, then all four die together -- the
# exact assertion sequence dumpster's test makes.

type
  # A field whose destructor bumps a per-node counter when the cell is freed;
  # `slot` is nil in any moved-from temporary, so those don't miscount.
  DropCount = object
    slot: ptr int
  Node = ref object
    refs: seq[Node]
    dc: DropCount

proc `=destroy`(x: DropCount) =
  if x.slot != nil: inc x.slot[]

# Add an edge parent -> child. `child` is a by-value borrow, so the caller's
# handle keeps owning its reference -- this is Nim's equivalent of dumpster's
# `Gc::clone`. Building edges with `g1.refs.add g2` instead would *move* g2 at
# its last read and silently collapse the graph's root set.
proc link(parent, child: Node) = parent.refs.add child

# drops[0] is unused; nodes are 1..4 to mirror the blog's gc1..gc4. The four
# handles live in an array so each stays an independent, still-owning root.
var drops: array[5, int]

proc scenario =
  var g: array[1..4, Node]
  for i in 1..4: g[i] = Node(dc: DropCount(slot: addr drops[i]))
  link(g[2], g[1])          # 2 -> 1
  link(g[3], g[1])          # 3 -> 1
  link(g[4], g[2])          # 4 -> 2
  link(g[4], g[3])          # 4 -> 3
  link(g[1], g[4])          # 1 -> 4  (closes both cycles)

  GC_fullCollect()
  doAssert drops == [0, 0, 0, 0, 0], "nothing dead yet"

  g[1] = nil        # node1 still held by node2 and node3
  GC_fullCollect()
  doAssert drops == [0, 0, 0, 0, 0], "dropping root 1 frees nothing"

  g[2] = nil        # node2 still held by node4
  GC_fullCollect()
  doAssert drops == [0, 0, 0, 0, 0], "dropping root 2 frees nothing"

  g[3] = nil        # node3 still held by node4
  GC_fullCollect()
  doAssert drops == [0, 0, 0, 0, 0], "dropping root 3 frees nothing"

  g[4] = nil        # last external handle gone: the whole SCC is garbage
  GC_fullCollect()
  doAssert drops == [0, 1, 1, 1, 1], "the full cycle is reclaimed at once"

scenario()
echo "ok"
