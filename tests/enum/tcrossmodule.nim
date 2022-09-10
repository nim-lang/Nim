import mcrossmodule

type
  MyEnum = enum
    Success

template t =
  doAssert some(Success)

t()
