# bug #14219
var vectors = @["a", "b", "c", "d", "e"]

iterator testVectors(): string =
  for vector in vectors:
    yield vector

var r = ""
for item in testVectors():
  r.add item
echo r

# bug #12990
iterator test(): int {.closure.} =
  yield 0

let x = test
while true:
  let val = x()
  if finished(x): break
  echo val
