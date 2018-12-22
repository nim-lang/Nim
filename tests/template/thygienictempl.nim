discard """
action: compile
"""


var
  e = "abc"

raise newException(IOError, e & "ha!")

template t() = echo(foo)

var foo = 12
t()


template test_in(a, b, c: untyped): bool {.dirty.} =
  var result {.gensym.}: bool = false
  false

when true:
  assert test_in(ret2, "test", str_val)
