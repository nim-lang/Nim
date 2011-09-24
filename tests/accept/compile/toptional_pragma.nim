# Test the optional pragma

proc p(x, y: int): int {.optional.} = 
  return x + y

# test that it is inherited from generic procs too:
proc q[T](x, y: T): T {.optional.} = 
  return x + y


p(8, 2)
q[float](0.8, 0.2)

