discard """
  output: '''some string here
dying some string here'''
"""

var
  someGlobal: string = "some string here"
  perThread {.threadvar.}: string

proc setPerThread() =
  {.gcsafe.}:
    deepCopy(perThread, someGlobal)

proc threadDied() {.gcsafe} =
  echo "dying ", perThread

proc foo() {.thread.} =
  echo perThread

proc main =
  onThreadCreation setPerThread
  onThreadDestruction threadDied
  var t: Thread[void]
  createThread[void](t, foo)
  t.joinThread()

main()
