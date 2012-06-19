import  macros

macro test*(a: stmt): stmt =
  var nodes: tuple[a, b: int]  
  nodes.a = 4
  nodes[1] = 45
  
  type
    TTypeEx = object
      x, y: int
      case b: bool
      of false: nil
      of true: z: float
      
  var t: TTypeEx
  t.b = true
  t.z = 4.5

test:
  "hi"

macro dump(n: stmt): stmt =
  dump(n)
  if kind(n) == nnkNone:
    nil
  else:
    hint($kind(n))
    for i in countUp(0, len(n)-1):
      nil

