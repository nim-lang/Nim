# Create connection encrypted using preshared key (TLS-PSK).
import net

static: assert defined(ssl)

let sock = newSocket()
sock.connect("localhost", Port(8800))

proc clientFunc(identityHint: string): tuple[identity: string, psk: string] =
  echo "identity hint ", identityHint.repr
  return ("foo", "psk-of-foo")

let context = newContext(cipherList="PSK-AES256-CBC-SHA")
context.clientGetPskFunc = clientFunc
context.wrapConnectedSocket(sock, handshakeAsClient)
context.destroyContext()
