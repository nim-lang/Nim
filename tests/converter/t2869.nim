discard """
  output: '''
TT[system.int]
ok
'''
"""

# bug #2869: generic converter whose generic param cannot be inferred
type
  TT[T] = object

converter conv[T](x: int): TT[T] = discard
converter conv[T](n: seq[T]): seq[seq[T]] = discard

var x = conv[int](0)
echo $typeof(x)

proc foo(n: string) = discard
doAssert not compiles(foo(0))
echo "ok"
