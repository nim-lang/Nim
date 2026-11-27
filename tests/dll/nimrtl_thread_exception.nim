discard """
  cmd: "nim $target --hints:on --define:useNimRtl $options $file"
  exitcode: 1
  outputsub: "Error: unhandled exception: boom [ValueError]"
"""

# An exception that escapes a thread must be reported. In a program that uses
# nimrtl the report read the current exception from the program's own copy of
# the exception state instead of nimrtl's, found none, and the program quit
# without a word.

proc worker() {.thread.} =
  raise newException(ValueError, "boom")

var t: Thread[void]
createThread(t, worker)
joinThread(t)
