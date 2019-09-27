discard """
outputsub: ""
"""

# output not testable because repr prints pointer addresses
# test the new "repr" built-in proc

type
  TEnum = enum
    en1, en2, en3, en4, en5, en6

  TPoint {.final.} = object
    x, y, z: int
    s: array[0..1, string]
    e: TEnum

var
  p: TPoint
  q: ref TPoint
  s: seq[ref TPoint]

p.x = 0
p.y = 13
p.z = 45
p.s[0] = "abc"
p.s[1] = "xyz"
p.e = en6

new(q)
q[] = p

s = @[q, q, q, q]

writeLine(stdout, repr(p))
writeLine(stdout, repr(q))
writeLine(stdout, repr(s))
writeLine(stdout, repr(en4))
