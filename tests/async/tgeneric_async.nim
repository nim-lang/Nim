
import asyncdispatch

when true:
  # bug #2377
  proc test[T](v: T) {.async.} =
    echo $v

  asyncCheck test[int](1)
