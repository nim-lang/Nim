discard """
  output: '''
42
43
44
'''
"""

# bug #21249: untyped argument of a template declared in a generic proc
type T = object
  a: int

proc bar(arg: int | float) =
  template withT(t: T, member: untyped): untyped =
    echo $(t.member)
  T(a: 42).withT(a)
  withT(T(a: 43), a)
  T(a: 44).withT a

bar(1)
