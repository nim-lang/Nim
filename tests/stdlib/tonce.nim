discard """
  cmd: "nim c -r --threads:on $options $file"
  matrix: "-d:caseA; -d:caseB"
"""
import std/once

when defined(caseA):
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
elif defined(caseB):
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
