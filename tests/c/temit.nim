discard """
  output: "509"
"""
# Test the new ``emit`` pragma:

{.emit: """
static int cvariable = 420;

""".}

proc embedsC() =
  var nimVar = 89
  {.emit: """printf("%d\n", cvariable + (int)`nimVar`);""".}

embedsC()
