# test macros without import
macro test0(x: untyped): untyped = x

block:
  var x = 0
  test0:
    x = 123
  assert x == 123

# issue # 25610
block:
  macro foo(u: untyped): untyped =
    discard

  macro bar(x: untyped): untyped = x

  bar:
    let x = 111

  assert x == 111
