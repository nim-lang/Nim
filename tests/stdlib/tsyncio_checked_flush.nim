discard """
  matrix: "-d:nimPreviewCheckedFlush"
  disabled: "win"
"""

# With -d:nimPreviewCheckedFlush, `flushFile` raises when the buffered data
# cannot be written instead of dropping it silently.

import std/[posix, assertions, syncio]

var fds: array[2, cint]
doAssert pipe(fds) == 0
doAssert close(fds[0]) == 0                      # nobody reads the pipe
doAssert signal(SIGPIPE, SIG_IGN) != SIG_ERR     # report EPIPE, do not exit

var f: File
doAssert open(f, FileHandle(fds[1]), fmWrite)
f.write "buffered"                               # stays in the stdio buffer
var raised = false
try:
  f.flushFile()
except IOError:
  raised = true
doAssert raised
f.close()
