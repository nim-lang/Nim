discard """
  output: '''
0
@[@[0, 1]]
'''
"""

type
  TrackySeq[T] = object
    s: seq[T]
    pos: int

proc foobar(ls: var TrackySeq[seq[int]], i: int): var seq[int] =
  echo ls.pos  # removing this, or making the return explicit works
  ls.s[i]

var foo: TrackySeq[seq[int]]
foo.s.add(@[0])
foo.foobar(0).add(1)
echo foo.s