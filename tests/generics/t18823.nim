type BitsRange[T] = range[0..sizeof(T)*8-1]

proc bar[T](a: T; b: BitsRange[T]) =
  discard

bar(1, 2.Natural)
