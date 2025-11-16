discard """
  description: "Test circular dependency detection"
  cmd: "nim c --experimental:dependencyResolution $file"
"""

{.experimental: "dependencyResolution".}

# Circular type dependencies should be merged
type
  Node = ref object
    value: int
    next: LinkedList
  
  LinkedList = ref object
    head: Node

# Test that types work
var list = LinkedList(head: Node(value: 1, next: nil))
assert list.head.value == 1
