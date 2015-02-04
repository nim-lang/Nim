template foo(a: int, b: string) = discard
foo(1, "test")

proc bar(a: int, b: string) = discard
bar(1, "test")

template foo(a: int, b: string) = bar(a, b)
foo(1, "test")

block:
  proc bar(a: int, b: string) = discard
  template foo(a: int, b: string) = discard
  foo(1, "test")
  bar(1, "test")

proc baz =
  proc foo(a: int, b: string) = discard
  proc foo(b: string) =
    template bar(a: int, b: string) = discard
    bar(1, "test")

  foo("test")

  block:
    proc foo(b: string) = discard
    foo("test")
    foo(1, "test")

baz()
