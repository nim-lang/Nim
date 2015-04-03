discard """
  line: 28
  nimout: '''tgc_unsafe2.nim(22, 5) Warning: 'trick' is not GC-safe as it accesses 'global' which is a global using GC'ed memory
tgc_unsafe2.nim(26, 5) Warning: 'track' is not GC-safe as it calls 'trick'
tgc_unsafe2.nim(28, 5) Error: 'consumer' is not GC-safe as it calls 'track'
'''
  errormsg: "'consumer' is not GC-safe as it calls 'track'"
"""

import threadpool

type StringChannel = TChannel[string]
var channels: array[1..3, StringChannel]

type
  MyObject[T] = object
    x: T

var global: MyObject[string]
var globalB: MyObject[float]

proc trick(ix: int) =
  echo global.x
  echo channels[ix].recv()

proc track(ix: int) = trick(ix)

proc consumer(ix: int) {.thread.} =
  track(ix)

proc main =
  for ix in 1..3: channels[ix].open()
  for ix in 1..3: spawn consumer(ix)
  for ix in 1..3: channels[ix].send("test")
  sync()
  for ix in 1..3: channels[ix].close()

when isMainModule:
  main()
