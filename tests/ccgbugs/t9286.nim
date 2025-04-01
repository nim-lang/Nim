discard """
  action: run
"""

import options
type Foo  = ref object
  i:      int

proc next(foo: Foo): Option[Foo] =
  try:    doAssert(foo.i == 0)
  except Exception: return      # 2º: none
  return some(foo)    # 1º: some

proc test =
  let foo = Foo()
  var opt = next(foo) # 1º Some
  while isSome(opt) and foo.i < 10:
    inc(foo.i)
    opt = next(foo)   # 2º None
  doAssert foo.i == 1, $foo.i

test()
