discard """
  matrix: "--threads:on --gc:refc; --threads:on --gc:orc"
"""

import std/mutexes

type
  PassObj = object
    id: int

  Pass = ptr PassObj

block:
  proc worker(p: Pass) {.thread.} =
    var m: Mutex
    init(m)
    acquire(m)
    inc p.id
    release(m)
    # After leaving the function scope, 
    # the resource owned by `m` is freed.

  var p = cast[Pass](allocShared0(sizeof(PassObj)))
  var ts = newSeq[Thread[Pass]](10)
  for i in 0..<ts.len:
    createThread(ts[i], worker, p)

  joinThreads(ts)
  doAssert p.id == 10

block:
  proc worker(p: Pass) {.thread.} =
    var m: ReentrantMutex
    init(m)
    acquire(m)
    acquire(m)
    inc p.id
    release(m)
    release(m)
    # After leaving the function scope, 
    # the resource owned by `m` is freed.

  var p = cast[Pass](allocShared0(sizeof(PassObj)))
  var ts = newSeq[Thread[Pass]](10)
  for i in 0..<ts.len:
    createThread(ts[i], worker, p)

  joinThreads(ts)
  doAssert p.id == 10
