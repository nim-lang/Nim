discard """
  output: '''
OM
NIM
3
NIM
NIM
Hello server!
Hi there client!
'''"""
import std/socketstreams, net, streams

block UDP:
  var recvSocket = newSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
  var recvStream = newReadSocketStream(recvSocket)
  recvSocket.bindAddr(Port(12345), "127.0.0.1")

  var sendSocket = newSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
  sendSocket.connect("127.0.0.1", Port(12345))
  var sendStream = newWriteSocketStream(sendSocket)
  sendStream.write "NOM\n"
  sendStream.setPosition(1)
  echo sendStream.peekStr(2)
  sendStream.write "I"
  sendStream.setPosition(0)
  echo sendStream.readStr(3)
  echo sendStream.getPosition()
  sendStream.flush()

  echo recvStream.readLine()
  recvStream.setPosition(0)
  echo recvStream.readLine()
  recvStream.close()

block TCP:
  var server = newSocket()
  server.setSockOpt(OptReusePort, true)
  server.bindAddr(Port(12345))
  server.listen()

  var
    client = newSocket()
    clientRequestStream = newWriteSocketStream(client)
    clientResponseStream = newReadSocketStream(client)
  client.connect("127.0.0.1", Port(12345))
  clientRequestStream.writeLine("Hello server!")
  clientRequestStream.flush()

  var
    incoming: Socket
    address: string
  server.acceptAddr(incoming, address)
  var
    serverRequestStream = newReadSocketStream(incoming)
    serverResponseStream = newWriteSocketStream(incoming)
  echo serverRequestStream.readLine()
  serverResponseStream.writeLine("Hi there client!")
  serverResponseStream.flush()
  serverResponseStream.close()
  serverRequestStream.close()

  echo clientResponseStream.readLine()
  clientResponseStream.close()
  clientRequestStream.close()
