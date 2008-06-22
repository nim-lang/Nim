# Test array, record constructors

import
  io

type
  TComplexRecord = record
    s: string
    x, y: int
    z: float
    chars: set[Char]

proc testSem =
  var
    things: array [0..1, TComplexRecord] = [
      (chars: {'a', 'b', 'c'}, s: "hi", x: 69, y: 45, z: 0.0),
      (chars: {'a', 'b', 'c'}, s: "hi", x: 69, y: 45, z: 1.0)
    ]
  write(stdout, things[0].x)

const
  things: array [0..] of TComplexRecord = [
    (chars: {'a', 'b', 'c'}, s: "hi", x: 69, y: 45, z: 0.0),
    (chars: {'a', 'b', 'c'}, s: "hi", x: 69, y: 45) #ERROR
  ]
  otherThings = [  # the same
    (chars: {'a', 'b', 'c'}, s: "hi", x: 69, y: 45, z: 0.0),
    (chars: {'a', 'b', 'c'}, s: "hi", x: 69, y: 45)
  ]
