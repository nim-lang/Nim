
var
  e = "abc"

raise newException(EIO, e & "ha!")

template t() = echo(foo)

var foo = 12
t()


template test_in(a, b, c: expr): bool {.immediate, dirty.} =
  var result {.gensym.}: bool = false
  false

when isMainModule:
  assert test_in(ret2, "test", str_val)
