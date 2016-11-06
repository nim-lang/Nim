# bug #4672
type
  EnumContainer[T: enum] = object
    v: T
  SomeEnum {.pure.} = enum
    A,B,C

proc value[T: enum](this: EnumContainer[T]): T =
  this.v

var enumContainer: EnumContainer[SomeEnum]
discard enumContainer.value()
