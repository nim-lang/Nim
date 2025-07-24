# imported by mdotcall

proc baseAddr*[T](x: openarray[T]): pointer =
  cast[pointer](x)

proc shift*(p: pointer, delta: int): pointer =
  cast[pointer](cast[int](p) + delta)
