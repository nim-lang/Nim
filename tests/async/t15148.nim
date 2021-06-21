import asyncdispatch, asyncfile, os

const Filename = "t15148.txt"

proc saveEmpty() {.async.} =
  let
    text = ""
    file = openAsync(Filename, fmWrite)
  await file.write(text)
  file.close()

waitFor saveEmpty()
