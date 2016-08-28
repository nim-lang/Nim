discard """
  output: '''a'''
"""

# bug #4292

template foo(s: string): string = s
proc variadicProc*(v: varargs[string, foo]) = echo v[0]
variadicProc("a")
