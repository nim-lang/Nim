proc doSomething*(x, y: int): int =
  ## do something
  x + y

const
  a* = 1 ## echo 1234
  b* = "test"

type
  MyEnum* = enum
    foo, bar
