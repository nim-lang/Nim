discard """
  output: '''some string here
dying some string here'''
"""

var
  someGlobal: string = "some string here"
  perThread {.threadvar.}: string

proc threadDied() {.gcsafe.} =
  echo "dying ", perThread

proc foo() {.thread.} =
  onThreadDestruction threadDied
  {.gcsafe.}:
    deepCopy(perThread, someGlobal)
  echo perThread

proc main =
  var t: Thread[void]
  createThread[void](t, foo)
  t.joinThread()

main()
