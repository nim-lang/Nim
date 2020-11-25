discard """
  targets: "c js"
"""

# pending bug #7999, test stderr, stdout separately
import system/ansi_c

proc main =
  rawWrite(cstdout, "ok1")
  rawWrite(cstderr, "ok2")
  rawWrite(cstdout, "ok3\n")
  rawWrite(cstderr, "ok4\n")

static: main()
main()
