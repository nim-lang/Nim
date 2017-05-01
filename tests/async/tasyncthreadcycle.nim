discard """
  cmd: "nim c --threads:on $file"
  output: ""
  exitcode: 0
"""

import asyncdispatch

# https://github.com/nim-lang/Nim/issues/5299

proc asyncThread() {.thread.} =
  let fd = newAsyncNativeSocket()
  fd.closeSocket()

var threads = newSeq[ptr Thread[void]](8)

for c in 1..1_000:
  for i in 0..<threads.len():
    var t = cast[ptr Thread[void]](alloc0(sizeof(Thread[void])))
    threads[i] = t
    createThread(t[], asyncThread)

  for t in threads:
    joinThread(t[])
    dealloc(t)