import enet, strutils
var
  address: enet.TAddress
  server: PHost
  event: TEvent

if enetInit() != 0:
  quit "Could not initialize ENet"

address.host = EnetHostAny
address.port = 8024

server = enet.createHost(
  addr address, 32, 2,  0,  0)
if server == nil:
  quit "Could not create the server!"

while server.hostService(addr event, 2500) >= 0:
  case event.kind
  of EvtConnect:
    echo "New client from $1:$2".format(event.peer.address.host, event.peer.address.port)

    var
      msg = "hello"
      resp = createPacket(cstring(msg), msg.len + 1, FlagReliable)

    if event.peer.send(0.cuchar, resp) < 0:
      echo "FAILED"
    else:
      echo "Replied"
  of EvtReceive:
    echo "Recvd ($1) $2 ".format(
      event.packet.dataLength,
      event.packet.data)

    destroy(event.packet)

  of EvtDisconnect:
    echo "Disconnected"
    event.peer.data = nil
  else:
    discard

server.destroy()
enetDeinit()
