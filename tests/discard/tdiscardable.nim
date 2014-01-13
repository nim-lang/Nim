# Test the discardable pragma

proc p(x, y: int): int {.discardable.} = 
  return x + y

# test that it is inherited from generic procs too:
proc q[T](x, y: T): T {.discardable.} = 
  return x + y


p(8, 2)
q[float](0.8, 0.2)

