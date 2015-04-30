discard """
  output: '''@[0.9, 0.1]'''
"""

# bug #2304

type TV2*[T:SomeNumber] = array[0..1, T]
proc newV2T*[T](x, y: T=0): TV2[T] = [x, y]

let x = newV2T[float](0.9, 0.1)
echo(@x)
