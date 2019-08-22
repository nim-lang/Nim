discard """
action: compile
"""

# Test various aspects

# bug #572
var a=12345678901'u64

var x = (x: 42, y: (a: 8, z: 10))
echo x.y

import
  mvarious

type
  PA = ref TA
  PB = ref TB

  TB = object
    a: PA

  TA = object
    b: TB
    x: int

proc getPA(): PA =
  var
    b: bool
  b = not false
  return nil

# bug #501
proc f(): int = 54

var
  global: int

var
  s: string
  i: int
  r: TA

r.b.a.x = 0
global = global + 1
exportme()
write(stdout, "Hallo wie heißt du? ")
write(stdout, getPA().x)
s = readLine(stdin)
i = 0
while i < s.len:
  if s[i] == 'c': write(stdout, "'c' in deinem Namen gefunden\n")
  i = i + 1

write(stdout, "Du heißt " & s)

# bug #544

# yay, fails again
type Bar [T; I:range] = array[I, T]
proc foo*[T; I:range](a, b: Bar[T, I]): Bar[T, I] =
  when len(a) != 3:
    # Error: constant expression expected
    {.fatal:"Dimensions have to be 3".}
  #...
block:
  var a, b: Bar[int, range[0..2]]
  discard foo(a, b)

# bug #1788

echo "hello" & char(ord(' ')) & "world"
