discard """
  targets: "c cpp"
  disabled: "win"
  disabled: "osx"
  action: compile
"""

# bug #19046

import std/os

var t: Thread[void]

proc test = discard
proc main = 
  createThread(t, test)
  pinToCpu(t, 1)
main()