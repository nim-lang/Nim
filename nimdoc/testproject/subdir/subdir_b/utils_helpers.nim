proc funWithGenerics*[T, U: SomeFloat](a: T, b: U) = discard

# We check that presence of overloaded `fn2` here does not break
# referencing in the "parent" file (the one that includes this one)
proc fn2*(x: int, y: float, z: float) =
  discard
