discard """
  action: "run"
"""
import asyncdispatch
type
    Sync = object
    Async = object
    SyncRes = (Sync, string)
    AsyncRes = (Async, string)

proc foo(val: Sync | Async): Future[(Async, string) | (Sync, string)] {.multisync.} =
    return (val, "hello")

let
  myAsync = Async()
  mySync = Sync()

doAssert typeof(waitFor foo(myAsync)) is AsyncRes
doAssert typeof(foo(mySync)) is SyncRes
