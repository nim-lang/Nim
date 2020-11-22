proc f() =
  var s: seq[int]
  iterator a(): int =
    for x in s: yield x

  iterator b(): int =
    for x in a(): yield x

proc g(): iterator(): char =
  return iterator(): char =
    for i in "123123":
      yield i

var buf: string
for ch in g():
  buf &= ch

assert buf == "123123"

iterator h(): iterator(): char =
  for i in "hello":
    yield iterator(): char =
      yield i

var buf2: string
for it in h():
  for ch in it:
    buf2 &= ch

assert buf2 == "hello"
