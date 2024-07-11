discard """
  errormsg: "'=dup' is not available for type <Foo>, which is inferred from unavailable '=copy'; requires a copy because it's not the last read of 'otherTree'; another read is done here: tprevent_assign2.nim(51, 31); routine: preventThis"
  file: "tprevent_assign2.nim"
  line: 49
"""

type
  Foo = object
    x: int

proc `=destroy`(f: var Foo) = f.x = 0
proc `=copy`(a: var Foo; b: Foo) {.error.} # = a.x = b.x

proc `=sink`(a: var Foo; b: Foo) = a.x = b.x

proc createTree(x: int): Foo =
  Foo(x: x)

proc take2(a, b: sink Foo) =
  echo a.x, " ", b.x

when false:
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

proc preventThis() =
  var otherTree: Foo
  for i in 0..3:
    while true:
      if i == 0:
        otherTree = createTree(44)
      case i
      of 0:
        echo otherTree
        take2(createTree(34), otherTree)
      of 1:
        take2(createTree(34), otherTree)
      else:
        discard

#allowThis()
preventThis()
