import atomics

type
  AtomicWithGeneric*[T] = object
    value: Atomic[T]

proc initAtomicWithGeneric*[T](value: T): AtomicWithGeneric[T] =
  result.value.store(value)

