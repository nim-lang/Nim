discard """
output: '''
123
baz
'''
"""

# bug #5147

proc foo[T](t: T) =
  type Wrapper = object
    get: T
  let w = Wrapper(get: t)
  echo w.get

foo(123)
foo("baz")
