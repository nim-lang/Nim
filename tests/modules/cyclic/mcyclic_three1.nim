import mcyclic_three2 {.cyclic.}, mcyclic_three3 {.cyclic.}

type
  Node1* = ref object
    next*: Node2
  Gen*[T] = object
    val*: Node3

proc countNodes*(n: Node1): int =
  result = 1
  if n.next != nil:
    inc result
    if n.next.next != nil: inc result
