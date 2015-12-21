# Passes if it compiles
# From issue #1946

type
  Part = object
    index: int ## array index of argument to be accessed

proc foobar(): int =
    var x: Part
    if x.index < high(int):
        discard
    0

const x = foobar()
