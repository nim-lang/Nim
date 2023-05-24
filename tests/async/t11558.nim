discard """
output: "Hello\n9"
"""
import std/asyncdispatch

proc foo(): Future[string] {.async.} =
  "Hello"

proc bar(): Future[int] {.async.} =
  result = 9

echo waitFor foo()
echo waitFor bar()
