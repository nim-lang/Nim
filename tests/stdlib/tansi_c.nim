discard """
  targets: "c js"
"""

import system/ansi_c

proc main =
  rawWrite(cstdout, "ok1")
  rawWrite(cstderr, "ok2")

static: main()
main()
