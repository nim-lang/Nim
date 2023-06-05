discard """
  output: "69"
"""
# Test array, record constructors

type
  TComplexRecord = tuple[
    s: string,
    x, y: int,
    z: float,
    chars: set[char]]

const
  things: array[0..1, TComplexRecord] = [
    (s: "hi", x: 69, y: 45, z: 0.0, chars: {'a', 'b', 'c'}),
    (s: "hi", x: 69, y: 45, z: 1.0, chars: {})]
  otherThings = [  # the same
    (s: "hi", x: 69, y: 45, z: 0.0, chars: {'a', 'b', 'c'}),
    (s: "hi", x: 69, y: 45, z: 1.0, chars: {'a'})]

writeLine(stdout, things[0].x)
#OUT 69
