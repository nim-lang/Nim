discard """
  matrix: "--mm:refc; --mm:orc"
"""

import std/rlocks
import std/assertions

var r: RLock
r.initRLock()
doAssert r.tryAcquire()
doAssert r.tryAcquire()
r.release()
r.release()

block:
  var x = 12
  withRLock r:
    inc x
  doAssert x == 13

r.deinitRLock()
