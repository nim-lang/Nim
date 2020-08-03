import asyncdispatch, asyncfile


proc saveEmpty() {.async.} =
  let
    text = ""
    file = open_async("t15148.txt", fmWrite)
  await file.write(text)
  file.close()

waitFor saveEmpty()
