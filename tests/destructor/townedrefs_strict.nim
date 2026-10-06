discard """
  matrix: "--mm:orc -d:nimOwnedStrict"
  exitcode: 1
  outputsub: "[FATAL] dangling references exist"
"""
# `-d:nimOwnedStrict` turns an unowned reference that outlives its owner into
# a diagnostic. Without it the reference keeps the object alive.
{.experimental: "ownedRefs".}
type Node = ref object
  next: owned Node
  data: int

var keep: seq[Node]
proc main =
  var root = Node(data: 1)
  keep.add root          # unowned counted copy
  echo root.data         # the owner is still used afterwards
main()                   # the owner dies, `keep[0]` outlives it
echo keep[0].data
