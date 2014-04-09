import sockets
var s: TSocket
s = socket()

s.connect("www.google.com", TPort(80))

var data: string = ""
s.readLine(data)
echo(data)


