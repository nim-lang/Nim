import mcrossmodule

type
  MyEnum = enum
    Success

template t =
  doAssert some(Success)

t()

block: # legacy support for behavior before overloadableEnums
  # warning: ambiguous enum field 'Success' assumed to be of type MyEnum
  let x = {Success}
  doAssert x is set[MyEnum]
