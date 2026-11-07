discard """
  nimout: '''
("baz", "hi")
("baz", "")
'''
  errormsg: "`b.len > 0`"
  file: "fatal.nim"
"""

# bug #12749: errors and output of a type's `static` argument were swallowed
proc baz(b: string): string =
  echo ("baz", b)
  doAssert b.len > 0
  return b

type Bar[T: static string] = object
  x: int

let a1 = Bar[baz("hi")](x: 12)
let a2 = Bar[baz("")](x: 12)
