discard """
  exitcode: 0
  output: "hello world"
  disabled: windows
"""

import asyncdispatch
import asyncfile

var asyncStdout = 1.AsyncFD.newAsyncFile()
proc doStuff: Future[void] {.async.} =
  await asyncStdout.write "hello world\n"

let fut = doStuff()
doAssert fut.finished, "Poll is needed unnecessarily. See #6846."
