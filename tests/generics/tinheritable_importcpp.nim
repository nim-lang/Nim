discard """
  targets: "cpp"
  action: compile
"""

# #4651
type
  Vector[T] {.importcpp: "std::vector<'0 >", header: "vector", inheritable.} = object
  VectorDerived {.importcpp: "SomeVectorDerived", nodecl.} = object of Vector[int]
  # Error: inheritance only works with non-final objects
