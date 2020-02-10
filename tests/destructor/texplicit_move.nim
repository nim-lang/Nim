
discard """
  cmd: '''nim c --gc:arc $file'''
  output: '''destroyed!
(f: 3)
(f: 0)
10
true
destroyed!
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
echo move(x)
echo x

# bug #9743
var a = new(int)
a[] = 10
var b = move a[]
echo a[]
let c = move(a)
echo a == nil
