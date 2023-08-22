import asyncdispatch, asyncnet

proc main {.async.} =
  proc f: Future[seq[int]] {.async.} =
    await newAsyncSocket().connect("www.google.com", Port(80))
  let x = await f()

asyncCheck main()
