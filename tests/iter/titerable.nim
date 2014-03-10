discard """
  output: '''2
4
6
4
8
12
'''
"""

iterator map[T, U](s: iterator:T{.inline.}, f: proc(x: T): U): U =
  for e in s: yield f(e)

template toSeq(s: expr): expr =
  var res = newSeq[type(s)](0)
  for e in s: res.add(e)
  res

var s1 = @[1, 2, 3]
for x in map(s1.items, proc (a:int): int = a*2):
  echo x

var s2 = toSeq(map(s1.items, proc (a:int): int = a*4))
for x in s2:
  echo x

