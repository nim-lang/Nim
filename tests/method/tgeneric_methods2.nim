#5432
type
  Iterator[T] = ref object of RootObj

# base methods with `T` in the return type are okay
method methodThatWorks*[T](i: Iterator[T]): T {.base.} =
  discard

# base methods without `T` (void or basic types) fail
method methodThatFails*[T](i: Iterator[T]) {.base.} =
  discard

type
  SpecificIterator1 = ref object of Iterator[string]
  SpecificIterator2 = ref object of Iterator[int]
