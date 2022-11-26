import std/asyncdispatch
discard """
action: "compile"
"""

proc foo(): Future[string] {.async.} =
  "Hello"

proc bar(): Future[int] {.async.} =
  result = 9

echo waitFor foo()
echo waitFor bar()
