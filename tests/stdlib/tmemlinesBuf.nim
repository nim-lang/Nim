import memfiles
var inp = memfiles.open("tests/dummy.txt")
var buffer: TaintedString = ""
for line in lines(inp, buffer):
  echo("#" & line & "#")
close(inp)
