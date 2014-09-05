discard """
  file: "tasyncexceptions.nim"
  exitcode: 0
"""
import asyncfile, asyncdispatch, os

proc main() {.async.} =
  var file = openAsync(getTempDir() / "foobar.txt", fmReadWrite)
  await file.write("test")
  file.setFilePos(0)
  let data = await file.readAll()
  doAssert data == "test"

waitFor main()
