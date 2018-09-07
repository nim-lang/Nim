
type
  SomeType* = int

proc someType*(): SomeType =
  ## constructor.
  SomeType(2)
