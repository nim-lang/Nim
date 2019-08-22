discard """
output: '''
@[1.0, 2.0, 3.0]
@[1.0, 2.0, 3.0]
'''
"""

# bug #6406

import sequtils

proc remap1(s: seq[int], T: typedesc): seq[T] =
  s.map do (x: int) -> T:
    x.T

proc remap2[T](s: seq[int], typ: typedesc[T]): seq[T] =
  s.map do (x: int) -> T:
    x.T

echo remap1(@[1,2,3], float)
echo remap2(@[1,2,3], float)
