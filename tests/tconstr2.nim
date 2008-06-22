# Test array, record constructors

type
  TComplexRecord = record
    s: string
    x, y: int
    z: float
    chars: set[char]

const
  things: array [0.., TComplexRecord] = [
    (chars: {'a', 'b', 'c'}, s: "hi", x: 69, y: 45, z: 0.0),
    (chars: {'a', 'b', 'c'}, s: "hi", x: 69, z: 0.3, y: 45)]
  otherThings = [  # the same
    (chars: {'a', 'b', 'c'}, s: "hi", x: 69, y: 45, z: 0.0),
    (z: 0.0, chars: {'a', 'b', 'c'}, s: "hi", x: 69, y: 45)]

write(stdout, things[0].x)
#OUT 69

