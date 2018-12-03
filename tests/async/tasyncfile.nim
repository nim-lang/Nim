discard """
output: '''
13
hello humans!
13
'''
"""
import asyncfile, asyncdispatch, os

proc main() {.async.} =
  let fn = getTempDir() / "foobar.txt"
  removeFile(fn)

  # Simple write/read test.
  block:
    var file = openAsync(fn, fmReadWrite)
    await file.write("testing")
    file.setFilePos(0)
    await file.write("foo")
    file.setFileSize(4)
    file.setFilePos(0)
    let data = await file.readAll()
    doAssert data == "foot"
    file.close()

  # Append test
  block:
    var file = openAsync(fn, fmAppend)
    await file.write("\ntest2")
    let errorTest = file.readAll()
    yield errorTest
    doAssert errorTest.failed
    file.close()
    file = openAsync(fn, fmRead)
    let data = await file.readAll()

    doAssert data == "foot\ntest2"
    file.close()

  # Issue #5531
  block:
    removeFile(fn)
    var file = openAsync(fn, fmWrite)
    await file.write("test2")
    file.close()
    file = openAsync(fn, fmWrite)
    await file.write("t3")
    file.close()
    file = openAsync(fn, fmRead)
    let data = await file.readAll()
    doAssert data == "t3"
    file.close()

  # Issue #7347
  block:
    var file = openAsync( parentDir(currentSourcePath) / "hello.txt")
    echo file.getFileSize()
    echo await file.readAll()
    echo file.getFilePos()

waitFor main()
