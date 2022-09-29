import mcrossmodule

type
  MyEnum = enum
    Success

template t =
  doAssert some(Success)

t()

block: # behavior before overloadableEnums
  # in case of ambiguity in closed environment, pick latest enum in scope
  let x = {Success}
  doAssert x is set[MyEnum]
