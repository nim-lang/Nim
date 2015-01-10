discard """
  ccodecheck: "!@('{' \\s* 'NI HEX3Astate;' \\s* '}')"
"""

# bug #1803
type TaskFn = iterator (): float

iterator a1(): float {.closure.} =
    var k = 10
    while k > 0:
        echo "a1 ", k
        dec k
        yield 1.0


iterator a2(): float {.closure.} =
    var k = 15
    while k > 0:
        echo "a2 ", k
        dec k
        yield 2.0

var
  x = a1
  y = a2
  z: TaskFn

discard x()
z = x #shallowCopy(z, x)
z = y #shallowCopy(z, y)
discard x()
