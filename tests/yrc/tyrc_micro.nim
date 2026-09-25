discard """
  cmd: "nim c --mm:yrc -d:useMalloc --threads:on $file"
  output: "done"
  valgrind: "leaks"
  disabled: "windows"
  disabled: "freebsd"
  disabled: "openbsd"
"""

# Smallest possible cycle: a three-node ring that is dead the instant `mk`
# returns. GC_fullCollect must reclaim it without touching freed memory.

type Node = ref object
  next: Node

proc mk =
  let a = Node()
  let b = Node()
  let c = Node()
  a.next = b
  b.next = c
  c.next = a

mk()
GC_fullCollect()
echo "done"
