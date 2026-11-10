discard """
  errormsg: "illegal recursion in type 'Node[system.int]'"
  line: 16
"""

# bug #15186: the same, through a `ref object` that contains the recursive
# object, and without constructing it.

type
  Node[T] = object
    item: T
    next: Node[T]
  Bag*[T] = ref object
    first: Node[T]

var b = new(Bag[int])
