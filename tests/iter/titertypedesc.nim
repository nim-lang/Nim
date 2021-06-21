discard """
  output: '''0
(id: 0)
@[]
[0, 0, 0]'''
"""

iterator foo*(T: typedesc): T =
  var x: T
  yield x

for a in foo(int): echo a
for b in foo(tuple[id: int]): echo b
for c in foo(seq[int]): echo c

type Generic[T] = T
for d in foo(Generic[array[0..2, int]]): echo d
