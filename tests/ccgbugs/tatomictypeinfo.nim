discard """
  matrix: "--mm:refc; --mm:orc"
  targets: "c cpp"
"""

# issue #24159 

import std/atomics

type N = object
  u: ptr Atomic[int]
proc w(args: N) = discard
var e: Thread[N]
createThread(e, w, default(N))
