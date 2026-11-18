discard """
  output: '''
[1, 2, 3, 4, 0, 0, 0, 0]
[9, 2, 3, 4, 0, 0, 0, 0]
'''
"""

# bug #7272: slice assignment through a pointer inside a template
template derefTesting(foo: array[4, byte]) =
  var bar: array[2, uint32]
  let barBytes = cast[ptr array[8, byte]](addr bar)
  barBytes[0..<4] = foo
  echo barBytes[]
  barBytes[0] = 9
  echo barBytes[]

var a: array[4, byte] = [1'u8, 2, 3, 4]
derefTesting(a)
