discard """
  output: '''
(1, 2)
(1, 2)
[1, 2]
(a: 1, b: 2)
3
ab
@[1] 2
x 2
'''
"""

# bug #26355: `yield` in expression in closure iterator creates incorrect
# results; operands must be evaluated left-to-right.

type Obj = object
  a, b: int

var d = 1

proc foo(a, b: int): (int, int) = (a, b)
proc bar(x: var int; y: int): int =
  x += y
  result = x
proc baz(x: openArray[int]; y: int): string = $(@x) & " " & $y
proc sinky(x: sink string; y: int): string = x & " " & $y

iterator v: int {.closure.} =
  doAssert (d, (d = 2; yield 0; d)) == (1, 2)
  d = 1
  echo (d, (d = 2; yield 0; d))
  d = 1
  echo foo(d, (d = 2; yield 0; d))
  d = 1
  echo [d, (d = 2; yield 0; d)]
  d = 1
  echo Obj(a: d, b: (d = 2; yield 0; d))
  # `var` parameters keep referring to the location
  var x = 1
  echo bar(x, (x = 2; yield 0; 1))
  inc(x, (x = 5; yield 0; 1))
  x += (x = x + 1; yield 0; 1)
  doAssert x == 8
  var s = "a"
  echo s & (d = 0; yield 0; "b")
  var q = @[1]
  echo baz(q, (d = 0; yield 0; 2))
  var str = "x"
  echo sinky(str, (str = "y"; yield 0; 2))

for _ in v(): discard
