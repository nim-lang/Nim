discard """
  cmd: "nim c --mm:yrc -d:useMalloc --threads:on $file"
  output: "ok"
  disabled: "windows"
  disabled: "freebsd"
  disabled: "openbsd"
"""

# Memory must stay bounded while creating cyclic garbage forever: the
# collector has to keep pace with allocation. A leak shows up as unbounded
# peak occupancy, which the assertion below catches.

type Node = ref object
  next: Node
  data: seq[int]

proc mk(n: int) =
  var h = Node(data: newSeq[int](4))
  var c = h
  for i in 1 ..< n:
    c.next = Node(data: newSeq[int](4))
    c = c.next
  c.next = h

var peak = 0
for round in 0 ..< 30:
  for i in 0 ..< 10_000:
    mk(8)
  let occ = getOccupiedMem()
  if occ > peak: peak = occ
doAssert peak < 64 * 1024 * 1024, "memory exploded: leak"
GC_fullCollect()
echo "ok"
