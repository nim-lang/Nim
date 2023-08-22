# issue 7705, 7703, 7702
discard """
  output: '''
z
e
'''
"""

type
  Reversable*[T] = concept a
    a[int] is T
    a.high is int
    a.len is int
    a.low is int

proc get[T](s: Reversable[T], n: int): T =
  s[n]

proc hi[T](s: Reversable[T]): int =
  s.high

proc lo[T](s: Reversable[T]): int =
  s.low

iterator reverse*[T](s: Reversable[T]): T =
  assert hi(s) - lo(s) == len(s) - 1
  for z in hi(s).countdown(lo(s)):
    yield s.get(z)

for s in @["e", "z"].reverse:
  echo s
