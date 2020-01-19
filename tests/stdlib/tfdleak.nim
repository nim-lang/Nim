discard """
  exitcode: 0
  output: ""
"""

import os, osproc, strutils

proc leakCheck(f: File, msg: string) =
  discard startProcess(
    getAppFilename(),
    args = @[$f.getOsFileHandle, msg],
    options = {poParentStreams}
  ).waitForExit -1

when defined(windows):
  proc openOsfHandle(handle: FileHandle, flags: cint): cint {.
    importc: "_open_osfhandle", header: "<io.h>".}

proc main() =
  if paramCount() == 0:
    # Parent process
    let f = open("__test_fdleak", fmReadWrite)
    defer: close f

    leakCheck(f, "open(string)")

    doAssert f.reopen("__test_fdleak2", fmReadWrite), "reopen failed"

    leakCheck(f, "reopen")

    var f2: File
    defer: close f2
    doAssert open(f2, f.getFileHandle), "open with FileHandle failed"

    leakCheck(f2, "open(FileHandle)")
  else:
    let fd = parseInt(paramStr 1)
    when defined(posix):
      var f: File
      if open(f, fd.FileHandle):
        echo "leaked ", paramStr 2
    else:
      if openOsfHandle(fd.FileHandle, 0) != -1:
        echo "leaked ", paramStr 2

when isMainModule: main()
