import memfiles
var inp = memfiles.open("tests/stdlib/tmemlinesBuf.nim")
var buffer: TaintedString = ""
for line in lines(inp, buffer):
  echo("#" & line & "#")
close(inp)
