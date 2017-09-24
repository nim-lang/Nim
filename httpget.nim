import asyncdispatch, asyncnet

proc runClient() {.async.} =
  var client = newAsyncSocket()
  await client.connect("google.com", Port(80))

  await client.send("GET / HTTP/1.1\c\l\c\l")
  while true:
    let line = await client.recvLine()
    if line.len == 0: break # Disconnected

    echo(line)

waitFor runClient()
