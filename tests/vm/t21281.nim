discard """
  nimout: '''
3
3
'''
"""

proc f(x: static[auto]) =  # doesn't work
  static: echo x
proc g[T](x: static[T]) =  # works
  static: echo x
f(3)
g(3)