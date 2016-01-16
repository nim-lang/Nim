proc foo(x: int) : auto =

  proc helper() : int = x
  proc bar() : int = helper()
  proc baz() : int = helper()

  return (bar, baz)