template run[T](): T = default(T)

doAssert run[int]() == 0
