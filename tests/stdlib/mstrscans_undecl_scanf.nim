import std/strscans

proc scan*[T](s: string): (bool, string) =
  s.scanTuple("$+")
