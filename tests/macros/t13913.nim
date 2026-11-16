discard """
  nimout: '''
nnkClosedSymChoice
nnkClosedSymChoice
nnkClosedSymChoice
'''
"""

# bug #13913
import std/[macros, math]
macro foo(fns: varargs[typed]): untyped =
  for t in fns:
    echo t.kind
  result = newEmptyNode()
foo(sqrt, pow, ln)
