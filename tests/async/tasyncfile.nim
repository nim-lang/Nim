discard """
  file: "tasyncfile.nim"
  exitcode: 0
"""
import asyncfile, asyncdispatch, os

proc main() {.async.} =
  let fn = getTempDir() / "foobar.txt"
  removeFile(fn)

  # Simple write/read test.
  block:
    var file = openAsync(fn, fmReadWrite)
    await file.write("test")
    file.setFilePos(0)
    await file.write("foo")
    file.setFilePos(0)
    let data = await file.readAll()
    doAssert data == "foot"
    file.close()

  # Append test
  block:
    var file = openAsync(fn, fmAppend)
    await file.write("\ntest2")
    let errorTest = file.readAll()
    await errorTest
    doAssert errorTest.failed
    file.close()
    file = openAsync(fn, fmRead)
    let data = await file.readAll()

    doAssert data == "foot\ntest2"
    file.close()

waitFor main()
