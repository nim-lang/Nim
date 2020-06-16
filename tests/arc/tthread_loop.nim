discard """
  output: "test ok"
  cmd: "nim c --gc:arc --threads:on $file"
"""

var threads: array[5, Thread[void]]

proc threadFn() {.thread.} =
  discard

proc main =
  for i in 0 ..< 5:
    createThread(threads[i], threadFn)
  joinThreads(threads)
  echo "test ok"

main()