import sockets
var s: TSocket
s = socket()

s.connect("www.google.com", TPort(80))

var recvData: string = ""
echo(s.recvLine(recvData))
echo(recvData)


