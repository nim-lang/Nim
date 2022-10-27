# the following code will break compilation without any error or hint
# `exited with code=3221225725`
type A[I: SomeOrdinal, E] = tuple # same for object
  length: int
 
echo A.sizeof # works without the following proc
 
proc newA*[I: SomeOrdinal, E](): A[I, E] = # works without `SomeOrdinal`
  discard

discard newA[uint8, int]()
