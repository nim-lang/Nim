func r(): auto =
  func(): int = 2
doAssert r()() == 2

block: # issue #11726
  let foo = block:
    var x: int
    proc = inc x # "identifier expected, but got '='"

  template paint(): untyped =
    proc (s: string): string = s

  let s = paint()
  doAssert s("abc") == "abc"
