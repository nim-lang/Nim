
type Node = tuple[left: ref Node]

proc traverse(root: ref Node) =
  if root.left != nil: traverse(root.left)
  
type A = tuple[B: ptr A]
proc C(D: ptr A) = C(D.B)


