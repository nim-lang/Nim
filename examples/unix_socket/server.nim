import net

let sock = newSocket(AF_UNIX, SOCK_STREAM, IPPROTO_IP)
sock.bindUnix("sock")
sock.listen()

while true:
  var client = new(Socket)
  sock.accept(client)
  var output = ""
  output.setLen 32
  client.readLine(output)
  echo "got ", output
  client.close()
