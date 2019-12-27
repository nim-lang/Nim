
discard """
  output: '''3
0
0
10
destroyed!
'''
joinable: false
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

# bug #9743
let a = create int
a[] = 10
var b = move a[]
echo a[]
echo b
