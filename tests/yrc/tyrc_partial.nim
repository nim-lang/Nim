discard """
  cmd: "nim c --mm:yrc -d:useMalloc --threads:on $file"
  output: "ok"
  valgrind: "leaks"
  disabled: "windows"
  disabled: "freebsd"
  disabled: "openbsd"
"""

# Exercise the manual collection API: disable automatic collections, build a
# batch of dead cycles, then reclaim them in halves via GC_partialCollect and
# confirm the pending count shrinks accordingly.

type Node = ref object
  next: Node

proc mk(n: int) =
  var h = Node()
  var c = h
  for i in 1 ..< n: (c.next = Node(); c = c.next)
  c.next = h

GC_disableOrc()   # no automatic collections; exercise the partial API
for i in 0 ..< 300: mk(4)
let pending = GC_prepareOrc()
doAssert pending > 0
GC_partialCollect(pending div 2)          # collect only the upper half
let remaining = GC_prepareOrc()
doAssert remaining <= pending div 2, $remaining & " vs " & $pending
GC_partialCollect(0)                      # collect the rest
doAssert GC_prepareOrc() == 0
GC_fullCollect()
echo "ok"
