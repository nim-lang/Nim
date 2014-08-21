discard """
  output: '''10
true true
true false
false true
false false'''
"""

var
  x = false
  run = true

while run:
  run = false
  block myblock:
    if true:
      break
    echo "leaving myblock"
  x = true
doAssert(x)

# bug #1418
iterator foo: int =
  for x in 0 .. 9:
    for y in [10,20,30,40,50,60,70,80,90]:
      yield x + y

for p in foo():
  echo p
  break

iterator permutations: int =
  yield 10

for p in permutations():
  break

# regression:
proc main =
  for x in [true, false]:
    for y in [true, false]:
      echo x, " ", y

main()
