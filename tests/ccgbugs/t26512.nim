discard """
  matrix: "--mm:refc; --mm:orc"
  output: '''
@[1]
abc
@[1, 2]
(x: @[5], y: "ab")
'''
"""

# bug #26512: `var b = if c: a else: ...` must copy `a`, not alias it

proc main(c: bool) =
  var a = @[1]
  var b = if c: a else: @[0]
  b[0] = 2
  echo a
  var s = "abc"
  var t = case c
          of true: s
          else: "x"
  t[0] = 'z'
  echo s
  var a2 = @[1, 2]
  var b2 = block:
    a2
  b2.add 3
  echo a2
  var obj = (x: @[5], y: "ab")
  var obj2 = if c: obj else: (x: @[0], y: "")
  obj2.x[0] = 9
  obj2.y[0] = 'q'
  echo obj

main(true)
