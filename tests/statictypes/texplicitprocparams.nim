discard """
output: '''
(x: 100)
5
'''
"""

type
  OdArray*[As: static[int], T] = object
    x: int

proc initOdArray*[As: static[int], T](len: int): OdArray[As, T] =
  result.x = len

echo initOdArray[10, int](100)

proc doStatic[N: static[int]](): int = N
echo doStatic[5]()

