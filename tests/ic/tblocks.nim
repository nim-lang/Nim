# tests procs, templates and variables under block statements/expressions

block:
  proc foo(x: int): int {.compileTime.} = x + 10

  const X = foo(1)
  assert X == 11

  proc bar(x: int): int {.compileTime.} = foo(x) + X

  const Y = bar(100)
  assert Y == 121

  const Z = block:
    var a = Y
    foo(a)
  assert Z == 131

const Test0 = block:
  proc foo(x: int): int {.compileTime.} = x + 1
  var x = foo(123)
  x
assert Test0 == 124

block:
  proc foo(x: int): int = x + 10

  let x0 = foo(1)
  assert x0 == 11

  proc bar(x: int): int = foo(x)

  let x1 = bar(100)
  assert x1 == 110

  let x2 = block:
    var a = x1
    foo(a)
  assert x2 == 120

let test1 = block:
  proc foo(x: int): int = x + 7
  var x = foo(100)
  x
assert test1 == 107

block:
  template foo(x: untyped): untyped = x

  var x = 11
  foo:
    x += 100
  assert x == 111

  template bar(x: untyped): untyped =
    x
    foo(x)

  var y = 22
  bar:
    y += 1000
  assert y == 2022
