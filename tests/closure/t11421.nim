# bug #11421
proc foo: iterator =
  template x = echo y # undeclared identifier error
  return iterator =
    let y = "foo"
    x

proc bar: auto =
  template x = echo y # no error
  return iterator =
    let y = "bar"
    x

discard foo()
discard bar()
