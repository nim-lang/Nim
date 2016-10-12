discard """
  output: "true"
"""
# Issue https://github.com/nim-lang/Nim/issues/4262
import asyncdispatch, times

proc foo(): Future[int] {.async.} =
  return 1

proc bar(): Future[int] {.async.} =
  return await foo()

let start = epochTime()
let barFut = bar()

while not barFut.finished:
  poll(2000)

echo(epochTime() - start < 1.0)
