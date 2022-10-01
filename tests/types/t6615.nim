type
  SomeType* = ref object of RootRef
    poll*: proc(variable: SomeType = nil)