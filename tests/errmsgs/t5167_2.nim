discard """
cmd: "nim c --threads:on $file"
errormsg: "'threadFunc' doesn't have a concrete type, due to unspecified generic parameters."
line: 11
"""

proc threadFunc[T]() {.thread.} =
  let x = 0

var thr: Thread[void]
thr.createThread(threadFunc)

