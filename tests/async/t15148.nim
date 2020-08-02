import asyncdispatch, asyncfile


proc saveEmpty() {.async.} =
  let
    text = ""
    file = open_async("test.txt", fmWrite)
  await file.write(text)
  file.close()

waitFor saveEmpty()
