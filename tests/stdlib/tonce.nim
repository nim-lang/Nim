discard """
  matrix: "--gc:orc --threads:on"
"""
import std/once


block:
  var thr: array[0..4, Thread[void]]
  var block1: Once
  var count = 0
  initOnce(block1)
  proc threadFunc() {.thread.} =
    for i in 1 .. 10:
      once(block1):
        inc count
  for i in 0..high(thr):
    createThread(thr[i], threadFunc)
  joinThreads(thr)
  doAssert count == 1


block:
  var thr: array[0..4, Thread[void]]
  var count = 0
  proc threadFunc() {.thread.} =
    var block1: Once
    initOnce(block1)
    for i in 1 .. 10:
      once(block1):
        inc count
  for i in 0..high(thr):
    createThread(thr[i], threadFunc)
  joinThreads(thr)
  doAssert count == 5
