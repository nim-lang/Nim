import asyncdispatch, asyncnet

proc main {.async.} =
  proc f: PFuture[seq[int]] {.async.} =
    await newAsyncSocket().connect("www.google.com", TPort(80))
  let x = await f()

main()
