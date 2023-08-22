discard """
  action: "compile"
"""

import terminal
import std/syncio

proc test() {.raises:[IOError, ValueError].} =
  setBackgroundColor(stdout, bgRed)

test()
