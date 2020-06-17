discard """
  output: "test ok"
  cmd: "nim c --gc:arc --threads:on --stacktrace:off $file"
"""

proc threadFn() {.thread.} =
  discard

proc main =
  var threads: array[5, Thread[void]]

  for i in 0 ..< 5:
    createThread(threads[i], threadFn)
  joinThreads(threads)
  echo "test ok"

main()
