discard """
  output: '''
2
1
'''
"""

# bug #6411
template rewriteMinusOne{(a = a + 1)|(a += 1)}[T](a: T): untyped =
  a -= T(1)

var a = 3

a = a + 1
echo a
a += 1
echo a
