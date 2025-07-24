# issue #22699

type Private = distinct int

proc chop*[T](x: int): int =
  cast[int](cast[tuple[field: Private]](x))
