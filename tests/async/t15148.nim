import asyncdispatch, asyncfile, os

const filename = "t15148.txt"

proc saveEmpty() {.async.} =
  let
    text = ""
    file = open_async(filename, fmWrite)
  await file.write(text)
  file.close()

waitFor saveEmpty()

doAssert fileExists(filename)
