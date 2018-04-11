discard """
  file: "t6100.nim"
  exitcode: 0
  output: "10000000"
"""
import asyncdispatch

let done = newFuture[int]()
done.complete(1)

proc asyncSum: Future[int] {.async.} =
  for _ in 1..10_000_000:
    result += await done

echo waitFor asyncSum()