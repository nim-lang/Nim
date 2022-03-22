discard """
  output: '''10
string'''
"""

# bug #18059
type
  C = ref object of RootObj
    fn: ContProc
    ex: ref Exception

  ContProc = proc (c: C): C {.nimcall.}

proc noop(c: C): C = c

type
  Env[T] = ref object of C
    x: T

proc foo_cont[U](c: C): C =
  proc afterCall[V](c: C): C =
    echo Env[V](c).x

  c.fn = afterCall[U]
  return noop(c)

proc foo[T](x: T): C =
  return Env[T](fn: foo_cont[T], x: x)

proc tramp(c: sink C) =
  while c != nil and c.fn != nil:
    c = c.fn(c)

tramp foo(10)
tramp foo("string")
