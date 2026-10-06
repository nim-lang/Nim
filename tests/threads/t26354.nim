discard """
  matrix: "--mm:orc; --mm:refc"
  targets: "c"
  ccodecheck: "'joinThread' \\w* ')(tyObject_Thread__' \\w+ '* t_p0)'"
  output: "done"
"""

# bug #26354: `joinThread` used to take its `Thread` by value. Copying the
# object read `core` and `dataFn` while the thread itself cleared them on exit,
# a data race reported by ThreadSanitizer.

proc w() {.thread.} = discard

var t: Thread[void]
createThread(t, w)
joinThread(t)
doAssert not running(t)
echo "done"
