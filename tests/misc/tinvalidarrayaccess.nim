discard """
  errormsg: "type mismatch: got <TTestArr, int literal(2), int literal(50)>"
  line: 11
"""


type TTestArr = array[0..1, int16]
var f: TTestArr
f[0] = 30
f[1] = 40
f[2] = 50
f[3] = 60

echo(repr(f))
