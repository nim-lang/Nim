
discard """
  output: '''3
0
destroyed!'''
"""

type
  myseq* = object
    f: int

proc `=destroy`*(x: var myseq) =
  echo "destroyed!"

var
  x: myseq
x.f = 3
echo move(x.f)
echo x.f
