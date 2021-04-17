discard """
  joinable:false
  batchable:false
  action: "run"
  matrix: "--threads:on -d:ssl"
  targets: "c cpp"
  timeout:5
  output:'''
accepted connection
connected with aethelfridda
identity hint "bartholomew"
hello from aethelfridda
goodbye from bartholomew
'''
  sortoutput:true
"""
import net
from openssl import SSL_CTX_ctrl
#using channels_builtin
var serverChannel:Channel[bool]

proc clientFunc(identityHint: string): tuple[identity: string, psk: string] =
  echo "identity hint \"", identityHint,"\""
  return ("aethelfridda","aethelfridda-loves-"&identityHint)

proc servfunc(identity:string):string =
  echo "got id:",identity
  "psk-of-" & identity

proc client(){.thread.}=
  let context = newContext(cipherList="PSK-AES256-CBC-SHA")
  defer: context.destroyContext()

  #turn off tls1_3 to force connection over psk
  assert context.context.SSL_CTX_ctrl(124,0x0303,nil) > 0#SSL_CTX_set_max_proto_version(TLS1_2)

  context.clientGetPskFunc = clientFunc

  let sock = newSocket()
  defer: sock.close()

  sock.connect("localhost", Port(8800))
  context.wrapConnectedSocket(sock, handshakeAsClient)
  #send some data
  sock.send("hello from aethelfridda\r\l")
  echo sock.recvLine()

proc server(){.thread.}=
  let context = newContext(cipherList="PSK-AES256-CBC-SHA")
  context.pskIdentityHint = "bartholomew"
  context.serverGetPskFunc = proc(identity: string): string = identity & "-loves-bartholomew"
  context.sessionIdContext= "anything"

  let sock = newSocket()
  defer:
    sock.close()
    context.destroyContext()
  var boundAddr = true
  try:
    sock.bindAddr(Port(8800))
  except ValueError,OsError:
    boundAddr = false

  serverChannel.send(boundAddr)
  if not boundAddr:
    return

  sock.listen()
  var client = new(Socket)
  sock.accept(client)
  sock.setSockOpt(OptReuseAddr, true)
  echo "accepted connection"
  context.wrapConnectedSocket(client, handshakeAsServer)
  echo "connected with ", client.getPskIdentity()
  echo recvLine(client)
  client.send("goodbye from bartholomew\r\l")
proc main()=

  var
    srv,cli:Thread[void]
  serverChannel.open()
  defer: serverChannel.close()

  createThread(srv,server)
  #wait till we are signalled that server has bound the port
  if not serverChannel.recv():
    quit "failed to bind port"
  createThread(cli,client)
  joinThreads(srv,cli)

main()
