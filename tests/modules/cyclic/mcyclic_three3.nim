import mcyclic_three1 {.cyclic.}

type
  Node3* = ref object
    name*: string
    back*: Node1
    g: Gen[int]
