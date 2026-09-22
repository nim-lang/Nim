discard """
  targets: "cpp"
"""

# Packed C++ inheritance must retain the alignment of the base subobject.
type
  PackedA {.packed.} = object of RootObj
    a: char

  PackedB {.packed.} = object of PackedA
    b: char

  PackedC {.packed.} = object of PackedB
    c: char

doAssert sizeof(PackedA) == 2 * sizeof(RootObj)
doAssert sizeof(PackedB) == 2 * sizeof(RootObj)
doAssert sizeof(PackedC) == 2 * sizeof(RootObj)
