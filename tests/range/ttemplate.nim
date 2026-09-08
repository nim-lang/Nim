discard """
  output: '''
4
2
6
'''
"""

# bug #560
template test(): untyped =
  2 .. 6

var x: range[test()] = 4
echo x
echo low(typeof(x))
echo high(typeof(x))
