discard """
  output: '''some string here'''
"""

var
  someGlobal: string = "some string here"
  perThread {.threadvar.}: string

proc setPerThread() =
  {.gcsafe.}:
    deepCopy(perThread, someGlobal)

proc foo() {.thread.} =
  echo perThread

proc main =
  onThreadCreation setPerThread
  var t: Thread[void]
  createThread[void](t, foo)
  t.joinThread()

main()
