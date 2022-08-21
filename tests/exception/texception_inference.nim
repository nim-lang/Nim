discard """
  output: '''good'''
  cmd: "nim c --gc:orc -d:release $file"
"""

type
  Raising[T, E] = object

proc foo[T, Errors](x: proc (x: Raising[T, Errors])) {.raises: Errors.} =
  discard

proc callback(x: Raising[int, ValueError]) =
  echo "callback"

proc xy() {.raises: [ValueError].} =
  foo callback

proc x[E]() {.raises: [E, IOError].} =
  raise newException(E, "text here")

try:
  x[ValueError]()
except ValueError:
  echo "good"

proc callback2(x: Raising[int, IOError]) =
  discard

proc foo2[T, OtherErrors](x: proc(x: Raising[T, OtherErrors])) {.raises: [ValueError, OtherErrors].} =
  discard

foo2 callback2
