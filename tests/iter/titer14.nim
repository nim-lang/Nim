proc f() =
  var s: seq[int]
  iterator a(): int =
    for x in s: yield x

  iterator b(): int =
    for x in a(): yield x

proc y(n: ref int) = discard

proc w(n: ref int) =
  iterator a(): int = y(n)
  let x = a

w(nil)
