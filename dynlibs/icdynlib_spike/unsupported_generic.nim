import icdynlib

proc unsupported[T](value: T): T {.dynexport.} =
  value
