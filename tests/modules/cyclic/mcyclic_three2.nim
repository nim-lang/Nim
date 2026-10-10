import mcyclic_three3 {.cyclic.}

type
  Node2* = ref object
    next*: Node3
