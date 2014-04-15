import sockets
var s: TSocket
s = socket()
if s == InvalidSocket: osError(osLastError())

s.connect("www.google.com", TPort(80))

var data: string = ""
s.readLine(data)
echo(data)


