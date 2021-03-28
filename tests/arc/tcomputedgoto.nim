discard """
  cmd: '''nim c --gc:arc $file'''
  output: '''2
2'''
"""

type
  ObjWithDestructor = object
    a: int
proc `=destroy`(self: var ObjWithDestructor) =
  echo "destroyed"

proc `=`(self: var ObjWithDestructor, other: ObjWithDestructor) =
  echo "copied"

proc test(a: range[0..1], arg: ObjWithDestructor) =
  var iteration = 0
  while true:
    {.computedGoto.}

    let
      b = int(a) * 2
      c = a
      d = arg
      e = arg

    discard c
    discard d
    discard e

    inc iteration

    case a
    of 0:
      assert false
    of 1:
      echo b
      if iteration == 2:
        break

test(1, ObjWithDestructor())