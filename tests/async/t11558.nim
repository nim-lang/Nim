import std/asyncdispatch
discard """
output: "Hello\n9"
"""

proc foo(): Future[string] {.async.} =
  "Hello"

proc bar(): Future[int] {.async.} =
  result = 9

echo waitFor foo()
echo waitFor bar()
