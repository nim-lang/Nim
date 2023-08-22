import enet, strutils

if enetInit() != 0:
  quit "Could not initialize ENet"
var
  address: enet.TAddress
  event: TEvent
  peer: PPeer
  client: PHost

client = createHost(nil, 1, 2, 0, 0)
if client == nil:
  quit "Could not create client!"

if setHost(addr address, "localhost") != 0:
  quit "Could not set host"
address.port = 8024

peer = client.connect(addr address, 2, 0)
if peer == nil:
  quit "No available peers"

block:
  var bConnected = false
  while not bConnected:
    if client.hostService(event, 5000) > 0 and event.kind == EvtConnect:
      echo "Connected"
      bConnected = true
    else:
      echo "Connection failed"
      quit 0

var runServer = true
while client.hostService(event, 1000) >= 0 and runServer:
  case event.kind
  of EvtReceive:
    echo "Recvd ($1) $2 ".format(
      event.packet.dataLength,
      event.packet.data)
  of EvtDisconnect:
    echo "Disconnected"
    event.peer.data = nil
    runServer = false
  of EvtNone: discard
  else:
    echo repr(event)


client.destroy()
