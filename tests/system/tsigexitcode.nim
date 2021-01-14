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
    let fatalSigs = [SIGINT, SIGSEGV, SIGABRT, SIGFPE, SIGILL, SIGBUS,
                     SIGPIPE]
    for s in fatalSigs:
      let (_, exitCode) = execCmdEx(quoteShellCommand [getAppFilename(), $s])
      doAssert exitCode == 128 + s, "mismatched exit code for signal " & $s

main()
