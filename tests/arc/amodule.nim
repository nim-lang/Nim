var vectors = @["a", "b", "c", "d", "e"]

iterator testVectors(): string =
  for vector in vectors:
    yield vector

var r = ""
for item in testVectors():
  r.add item
echo r