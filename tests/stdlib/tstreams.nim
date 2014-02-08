import streams

var outp = newFileStream(stdout)
var inp = newFileStream(stdin)
write(outp, "Hello! What is your name?")
var line = readLine(inp)
write(outp, "Nice name: " & line)
