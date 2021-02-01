block: # bug #16822
  var scores: seq[(set[char], int)] = @{{'/'} : 10}

  var x1: set[char]
  for item in items(scores):
    x1 = item[0]

  doAssert x1 == {'/'}

  var x2: set[char]
  for (chars, value) in items(scores):
    x2 = chars

  doAssert x2 == {'/'}

block: # bug #14574
  proc fn(): auto =
    let a = @[("foo", (12, 13))]
    for (k,v) in a:
      return (k,v)
  doAssert fn() == ("foo", (12, 13))

block: # bug #14574
  iterator fn[T](a:T): lent T = yield a
  let a = (10, (11,))
  proc bar(): auto =
    for (x,y) in fn(a):
      return (x,y)
  doAssert bar() == (10, (11,))