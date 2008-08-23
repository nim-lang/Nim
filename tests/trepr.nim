# test the new "repr" built-in proc

type
  TPoint {.final.} = object
    x, y, z: int
    s: array [0..1, string]

  TEnum = enum
    en1, en2, en3, en4, en5, en6

var
  p: TPoint
  q: ref TPoint
  s: seq[ref TPoint]

p.x = 0
p.y = 13
p.z = 45
p.s[0] = "abc"
p.s[1] = "xyz"

new(q)
q^ = p

s = [q, q, q, q]

writeln(stdout, repr(p))
writeln(stdout, repr(q))
writeln(stdout, repr(s))
writeln(stdout, repr(nil))
writeln(stdout, repr(en4))
