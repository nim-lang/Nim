import streams

var outp = newFileStream(stdout)
var inp = newFileStream(stdin)
write(outp, "Hallo! What is your name?")
var line = readLine(inp)
write(outp, "nice name: " & line)
