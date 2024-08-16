type A[I: SomeOrdinal, E] = tuple # same for object
  length: int

doAssert A.sizeof == sizeof(int) # works without the following proc

proc newA*[I: SomeOrdinal, E](): A[I, E] = # works without `SomeOrdinal`
  discard

discard newA[uint8, int]()
