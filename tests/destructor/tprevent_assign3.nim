discard """
  errormsg: "'=copy' is not available for type <Foo>; requires a copy because it's not the last read of 'otherTree'"
  file: "tprevent_assign3.nim"
  line: 46
"""

type
  Foo = object
    x: int

proc `=destroy`(f: var Foo) = f.x = 0
proc `=`(a: var Foo; b: Foo) {.error.} # = a.x = b.x
proc `=sink`(a: var Foo; b: Foo) = a.x = b.x

proc createTree(x: int): Foo =
  Foo(x: x)

proc take2(a, b: sink Foo) =
  echo a.x, " ", b.x

proc allowThis() =
  var otherTree: Foo
  try:
    for i in 0..3:
      while true:
        #if i == 0:
        otherTree = createTree(44)
        case i
        of 0:
          echo otherTree
          take2(createTree(34), otherTree)
        of 1:
          take2(createTree(34), otherTree)
        else:
          discard
  finally:
    discard

proc preventThis2() =
  var otherTree: Foo
  try:
    try:
      otherTree = createTree(44)
      echo otherTree
    finally:
      take2(createTree(34), otherTree)
  finally:
    echo otherTree

allowThis()
preventThis2()


