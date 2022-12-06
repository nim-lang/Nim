import std/sequtils

block:
  block:
    var _ = 0
    proc f (): int {.used.} =
      return 0

let _ = "foo,bar,baz"
  .map(proc (c: char): char = c)
  .map(
    proc (c: char): char =
      return c
  )

proc f: bool {.used.} =
  return true
