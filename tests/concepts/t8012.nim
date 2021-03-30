type
  MyTypeCon = concept c
    c.counter is int
  MyType = object
    counter: int

proc foo(conc: var MyTypeCon) =
  conc.counter.inc
  if conc.counter < 5:
    foo(conc)

var x: MyType

x.foo
discard x.repr
