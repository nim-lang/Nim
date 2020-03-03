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

# Empty type in template is correctly disambiguated
block:
  template foo() =
    type M = object
      discard
    var y = M()

  foo()

  type M = object
    x: int

  var x = M(x: 1)
  doAssert(x.x == 1)
