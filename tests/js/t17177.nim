import std/asyncjs

proc fn1(n: int): Future[int] {.async.} = return n
proc main2() =
  proc fn2(n: int): Future[int] {.async.} = return n
proc main3(a: auto) =
  proc fn3(n: int): Future[int] {.async.} = return n
proc main4() {.async.} =
  proc fn4(n: int): Future[int] {.async.} = return n
  discard
