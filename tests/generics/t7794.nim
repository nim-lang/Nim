discard """
output: '''
10
2.0
'''
"""

type
  Data*[T:SomeNumber, U:SomeReal] = ref object
    x*: T
    value*: U

var d = Data[int, float64](x:10.int, value:2'f64)
echo d.x
echo d.value
