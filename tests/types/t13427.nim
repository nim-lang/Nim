discard """
  output: '''
1 1 1 1
GenProcType[system.int]
3
'''
"""

# bug #13427: a conversion to an uninstantiated generic proc type
type GenProcType[T] = proc(): T
proc mult(): int = 1
let
  a: GenProcType[int] = mult
  b = (GenProcType[int])mult
  c = (GenProcType)mult
  d = cast[GenProcType[int]](mult)
echo a(), " ", b(), " ", c(), " ", d()
echo typeof(c)

type Dist[T] = distinct T
let x = Dist(3)
echo x.int
