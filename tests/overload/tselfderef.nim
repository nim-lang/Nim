discard """
action: compile
"""

# bug #4671
{.experimental.}
{.this: self.}
type
  SomeObj = object
    f: int

proc f(num: int) =
  discard

var intptr: ptr int
intptr.f() # compiles fine

proc doSomething(self: var SomeObj) =
  var pint: ptr int
  pint.f() # Error: expression '.(pint, "f")' cannot be called
