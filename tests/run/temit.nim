discard """
  file: "temit.nim"
  output: "509"
"""
# Test the new ``emit`` pragma: 

{.emit: """
static int cvariable = 420;

""".}

proc embedsC() {.noStackFrame.} = 
  var nimrodVar = 89
  {.emit: """fprintf(stdout, "%d\n", cvariable + (int)`nimrodVar`);""".}

embedsC()




