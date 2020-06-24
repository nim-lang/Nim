discard """
  output: '''1,2
2,3
1,2
'''
"""

proc say(a, b: int) =
  echo a,",",b

var a = 1
say a, (a += 1; a)

var b = 1
say (b += 1; b), (b += 1; b)

type C = object {.byRef.}
  i: int

proc say(a, b: C) =
  echo a.i,",",b.i

proc `+=`(x: var C, y: C) = x.i += y.i

var c = C(i: 1)
say c, (c += C(i: 1); c)

