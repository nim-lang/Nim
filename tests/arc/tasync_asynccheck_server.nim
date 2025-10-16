discard """
  cmd: '''nim r --mm:orc $file'''
"""

import std/[asyncdispatch, asyncnet, strutils]
from stdtest/netutils import bindAvailablePort

when defined(gcArc) or defined(gcOrc):
  const
    mmName = when defined(gcArc): "arc" else: "orc"
    swarmSize = 3
    messagesPerClient = 4
    maxPollSpins = 256

  type
    TrackerObj = object
      id: int

  var
    destroyedCount = 0
    nextId = 0
    completedClients = 0

  proc `=destroy`(x: var TrackerObj) =
    inc destroyedCount

  proc newTracker(): ref TrackerObj =
    inc nextId
    new result
    result.id = nextId

  proc handleClient(client: AsyncSocket; tracker: ref TrackerObj) {.async.} =
    for i in 0..<messagesPerClient:
      let line = await client.recvLine()
      doAssert line.len > 0,
        mmName & " server should receive non-empty payload"
    await client.send("done\n")
    client.close()
    inc completedClients

  proc acceptLoop(server: AsyncSocket) {.async.} =
    while completedClients < swarmSize:
      try:
        let client = await server.accept()
        let tracker = newTracker()
        asyncCheck handleClient(client, tracker)
      except OSError:
        break

  proc runClient(port: Port; tracker: ref TrackerObj) {.async.} =
    let sock = await asyncnet.dial("127.0.0.1", port)
    for i in 0..<messagesPerClient:
      await sock.send($tracker.id & ":" & $i & "\n")
    let resp = await sock.recvLine()
    doAssert resp == "done",
      mmName & " client should receive completion marker"
    sock.close()

  proc launchClients(port: Port) {.async.} =
    for _ in 0..<swarmSize:
      let tracker = newTracker()
      asyncCheck runClient(port, tracker)

  proc main() =
    let server = newAsyncSocket()
    let port = bindAvailablePort(server.getFd())
    server.listen()

    asyncCheck acceptLoop(server)
    asyncCheck launchClients(port)

    var spins = 0
    while completedClients < swarmSize and spins < maxPollSpins:
      poll(0)
      inc spins

    doAssert completedClients == swarmSize,
      mmName & " asyncCheck server should handle all clients"

    server.close()

    var releaseSpins = 0
    let expected = swarmSize * 2
    while destroyedCount < expected and releaseSpins < maxPollSpins:
      poll(0)
      inc releaseSpins

    doAssert destroyedCount == expected,
      mmName & " asyncCheck server scenario should release tracked refs"

  main()
else:
  {.fatal: "This test must run with --mm:arc or --mm:orc".}
