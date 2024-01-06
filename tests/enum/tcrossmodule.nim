import mcrossmodule

type
  MyEnum = enum
    Success

template t =
  doAssert some(Success)

t()

block: # account for scope
  let x = {Success}
  doAssert x is set[MyEnum]
  proc foo[T](a: T): string = $a
  doAssert foo(Success) == "Success"
  proc bar[T](): string = $Success
  doAssert bar[int]() == "Success"
