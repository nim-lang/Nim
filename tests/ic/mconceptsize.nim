type Sized* = concept
  proc sizeOf(x: typedesc[Self]): int

proc sizeOf*[T: SomeInteger](x: typedesc[T]): int = sizeof(T)
