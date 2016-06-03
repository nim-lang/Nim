# Accept connection encrypted using preshared key (TLS-PSK).
import net

static: assert defined(ssl)

let sock = newSocket()
sock.bindAddr(Port(8800))
sock.listen()

let context = newContext(cipherList="PSK-AES256-CBC-SHA")
context.pskIdentityHint = "hello"
context.serverGetPskFunc = proc(identity: string): string = "psk-of-" & identity

while true:
  var client = new(Socket)
  sock.accept(client)
  sock.setSockOpt(OptReuseAddr, true)
  echo "accepted connection"
  context.wrapConnectedSocket(client, handshakeAsServer)
  echo "got connection with identity ", client.getPskIdentity()
