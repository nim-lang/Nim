discard """
output: "1\n2\n3"
"""

type
  MyConcept = concept x
    someProc(x)

  SomeSeq = seq[MyConcept]

proc someProc(x:int) = echo x

proc work (s: SomeSeq) =
  for item in s:
    someProc item

var s = @[1, 2, 3]
work s

