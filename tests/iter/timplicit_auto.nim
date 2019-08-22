# bug #1838

type State = enum Empty, Tree, Fire

const
  disp: array[State, string] = ["  ", "\e[32m/\\\e[m", "\e[07;31m/\\\e[m"]

proc univ(x, y: int): State = Tree

var w, h = 30

iterator fields(a = (0,0), b = (h-1,w-1)): auto =
  for y in max(a[0], 0) .. min(b[0], h-1):
    for x in max(a[1], 0) .. min(b[1], w-1):
      yield (y,x)

for y,x in fields():
  doAssert disp[univ(x, y)] == disp[Tree]
