discard """
  joinable:false
  batchable:false
  matrix: "--threads:on -d:ssl"
  targets: "c cpp"
  timeout:5
"""
import std/net
from std/openssl import SSL_CTX_ctrl

when defined(osx):
  {.passl:"-Wl,-rpath,/usr/local/opt/openssl/lib".}

# using channels_builtin
var serverChannel: Channel[Port]

proc clientFunc(identityHint: string): tuple[identity: string, psk: string] =
  doAssert identityHint == "bartholomew"
  return ("aethelfridda", "aethelfridda-loves-" & identityHint)

proc client(p: Port){.thread.}=
  let context = newContext(cipherList = "PSK-AES256-CBC-SHA")
  defer: context.destroyContext()

  # turn off tls1_3 to force connection over psk
  doAssert context.context.SSL_CTX_ctrl(124, 0x0303, nil) > 0 # SSL_CTX_set_max_proto_version(TLS1_2)
  context.clientGetPskFunc = clientFunc

  let sock = newSocket()
  defer: sock.close()

  sock.connect("localhost", p)
  context.wrapConnectedSocket(sock, handshakeAsClient)

  sock.send("hello from aethelfridda\r\l")
  doAssert sock.recvLine() == "goodbye from bartholomew"

proc server(){.thread.}=
  let context = newContext(cipherList="PSK-AES256-CBC-SHA")
  context.pskIdentityHint = "bartholomew"
  context.serverGetPskFunc = proc(identity: string): string = identity & "-loves-bartholomew"
  context.sessionIdContext= "anything"

  let sock = newSocket()
  defer:
    sock.close()
    context.destroyContext()
  sock.bindAddr(Port(0))
  let (_, port) = sock.getLocalAddr()
  serverChannel.send(port)
  sock.listen()
  var client = new(Socket)
  sock.accept(client)
  sock.setSockOpt(OptReuseAddr, true)
  context.wrapConnectedSocket(client, handshakeAsServer)
  doAssert client.getPskIdentity() == "aethelfridda"
  doAssert recvLine(client) == "hello from aethelfridda"
  client.send("goodbye from bartholomew\r\l")

proc main()=
  var
    srv:Thread[void]
    cli:Thread[Port]
  serverChannel.open()
  defer: serverChannel.close()

  createThread(srv,server)

  # wait for server to bind a port
  let port = serverChannel.recv()

  createThread(cli, client, port)

  joinThread(srv)
  joinThread(cli)

main()
