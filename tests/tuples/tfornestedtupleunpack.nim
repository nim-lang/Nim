discard """
  targets: "c js"
  output: '''
Outer: 1, Inner1: 2, Inner2: 3
Outer: 4, Inner1: 5, Inner2: 6
1 2 3 4
0 1 2 3
1 1 2 3
@[(10, (20, 30)), (10, (20, 30))]
@[(0, (7, 0)), (1, (7, 1))]
1 10 100
1 10 100
2 20 200
1 2 3
6
'''
"""

# nim-lang/nightlies#129
let data = @[
  (1, (2, 3)),
  (4, (5, 6))
]
for (outer, (inner1, inner2)) in data:
  echo "Outer: ", outer, ", Inner1: ", inner1, ", Inner2: ", inner2

for (a, (b, (c, d))) in [(1, (2, (3, 4)))]:
  echo a, " ", b, " ", c, " ", d

for i, (a, (b, c)) in [(1, (2, 3)), (1, (2, 3))]:
  echo i, " ", a, " ", b, " ", c

var x = @[(1, (2, 3)), (4, (5, 6))]
for (a, (b, c)) in x.mitems:
  a = 10
  b = 20
  c = 30
echo x

for i, (a, (b, c)) in x.mpairs:
  a = i
  b = 7
  c = i
echo x

iterator tuples: (int, (int, int)) =
  yield (1, (10, 100))

for (a, (b, c)) in tuples():
  echo a, " ", b, " ", c

iterator closureTuples: (int, (int, int)) {.closure.} =
  yield (1, (10, 100))
  yield (2, (20, 200))

for (a, (b, c)) in closureTuples():
  echo a, " ", b, " ", c

template t =
  for (a, (b, c)) in [(1, (2, 3))]:
    echo a, " ", b, " ", c
t()

const sum = block:
  var s = 0
  for (a, (b, c)) in [(1, (2, 3))]:
    s += a + b + c
  s
echo sum

# wrong arity / non-tuple in nested pattern
doAssert not compiles(for (a, (b, c)) in [(1, (2, 3, 4))]: discard)
doAssert not compiles(for (a, (b, c)) in [(1, 2)]: discard)
