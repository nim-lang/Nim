type
    A {.pure.} = enum
      left, right, up, down
    B {.pure.} = enum
      left, right, up, down
    Test = object
      case kind: A # Tests rec case inference
      of left:
        a: int
      of {right, down}:
        b: float
      else:
        c: string
block: # Tests case inference
  let test = A.left
  case test:
  of left: discard
  of up: discard
  else: discard

block: # Tests array inference
  var
    t: array[4, A] = [left, right, down, up]
    y: array[4, B] = [left, right, down, up]

block: # Tests set inference
  type ASet = set[A]
  var
    t: ASet = {left..right, down, up}
    y: set[B] = {left, right, down, up}

block: # Tests left enum inference
  var 
    t: A = left
    y: A = left
  


block: # Tests literal inference
  var 
    a: array[4, byte] = [255, 2, 3, 4]
    b: array[4, uint32] = [1, 2, 3, 4]
    c: int8 = 126