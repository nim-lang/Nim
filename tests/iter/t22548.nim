discard """
  action: compile
"""

type Xxx[T] = object

iterator x(v: string): char =
  var v2: Xxx[int]

  var y: v2.T

  echo y

proc bbb(vv: string): proc () =
  proc xxx() =
    for c in x(vv):
      echo c

  return xxx

bbb("test")()
