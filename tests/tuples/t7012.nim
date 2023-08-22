discard """
  errormsg: "illegal recursion in type 'Node'"
"""

type Node[T] = tuple
    next: ref Node[T]
var n: Node[int]