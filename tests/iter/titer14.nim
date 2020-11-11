proc f() =
  var s: seq[int]
  iterator a(): int =
    for x in s: yield x

  iterator b(): int =
    for x in a(): yield x
