discard """
  matrix: "--mm:arc; --mm:orc; --mm:orc -d:danger"
  exitcode: 1
  outputsub: "fatal error: string or seq size overflows the address space"
"""

# The size computations of the ARC/ORC seq implementation must not wrap
# around, otherwise a far too small block is allocated and then written to.

const huge = high(int) div 4 + 1 # `huge * sizeof(int)` wraps around to 0

proc main =
  var s = newSeq[int](huge)
  for i in 0 ..< s.len: s[i] = i
  echo "not reached"

main()
