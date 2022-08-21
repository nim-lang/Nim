discard """
  joinable: false
  disabled: windows
"""

import os, osproc, posix, strutils

proc main() =
  if paramCount() > 0:
    let signal = cint parseInt paramStr(1)
    discard posix.raise(signal)
  else:
    # synchronize this list with lib/system/except.nim:registerSignalHandler()
    let sigs = [SIGINT, SIGSEGV, SIGABRT, SIGFPE, SIGILL, SIGBUS, SIGPIPE]
    for s in sigs:
      let (_, exitCode) = execCmdEx(quoteShellCommand [getAppFilename(), $s])
      if s == SIGPIPE:
        # SIGPIPE should be ignored
        doAssert exitCode == 0, $(exitCode, s)
      else:
        doAssert exitCode == 128+s, $(exitCode, s)

main()
