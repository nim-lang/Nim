discard """
output: '''
3 4
4 5
5 6
6 7
7 8
(x: 3, y: 4)
(x: 4, y: 5)
(x: 5, y: 6)
(x: 6, y: 7)
(x: 7, y: 8)
'''
"""


iterator xrange(fromm, to: int, step = 1): tuple[x, y: int] =
  var a = fromm
  while a <= to:
    yield (a, a+1)
    inc(a, step)

for a, b in xrange(3, 7):
  echo a, " ", b

for tup in xrange(3, 7):
  echo tup
