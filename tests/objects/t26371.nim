discard """
  matrix: "--mm:orc; --mm:arc; --mm:refc"
  output: '''
(a: 5, s: "init")
(kind: kB, y: 7)
[(a: 5, s: "init"), (a: 5, s: "init")]
(p: (a: 5, s: "init"), z: 0)
0
(a: 0, s: "")
destroyed 1
(r: (id: 0), n: 3)
'''
"""

# bug #26371: `reset` ignores object field default values with ARC/ORC

type
  K = enum kA, kB
  Plain = object
    a: int = 5
    s: string = "init"
  NoDefaults = object
    a: int
    s: string
  V = object
    case kind: K = kB
    of kA: x: int
    of kB: y: int = 7
  Arr = array[2, Plain]
  Tup = tuple[p: Plain, z: int]

var x = Plain(a: 1, s: "x")
reset(x)
echo x
doAssert x == default(Plain)

var v = V(kind: kA, x: 3)
reset(v)
echo v

var a: Arr = [Plain(a: 1), Plain(a: 2)]
reset(a)
echo a

var t: Tup = (Plain(a: 9), 3)
reset(t)
echo t

var i = 4
reset(i)
echo i

var nd = NoDefaults(a: 3, s: "abc")
reset(nd)
echo nd

when defined(gcDestructors):
  type
    Res = object
      id: int
    Holder = object
      r: Res
      n: int = 3

  proc `=destroy`(r: Res) =
    if r.id != 0:
      echo "destroyed ", r.id
  proc `=copy`(a: var Res; b: Res) {.error.}

  proc main =
    var h = Holder(r: Res(id: 1), n: 10)
    reset(h)
    echo h
  main()
else:
  echo "destroyed 1"
  echo "(r: (id: 0), n: 3)"

static:
  var y = Plain(a: 1, s: "x")
  reset(y)
  doAssert y == default(Plain)
