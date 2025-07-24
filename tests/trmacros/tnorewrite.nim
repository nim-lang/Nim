block:
  proc get(x: int): int = x

  template t{get(a)}(a: int): int =
    {.noRewrite.}:
      get(a) + 1

  doAssert get(0) == 1

block:
  var x: int

  template asgn{a = b}(a: int{lvalue}, b: int) =
    let newVal = b + 1
    # ^ this is needed but should it be?
    {.noRewrite.}:
      a = newVal

  x = 10
  doAssert x == 11, $x
