discard """
  output: '''true'''
"""

var somethingElse {.threadvar.}: ref string

type MyThread = Thread[void]

proc asyncThread() {.thread.} =
  new somethingElse

var threads = newSeq[ptr Thread[void]](8)

for c in 1..1_000:
  #echo "Test " & $c
  for i in 0..<threads.len:
    var t = cast[ptr Thread[void]](alloc0(sizeof(MyThread)))
    threads[i] = t
    createThread(t[], asyncThread)

  for t in threads:
    joinThread(t[])
    dealloc(t)

echo "true"
