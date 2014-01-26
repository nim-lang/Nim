template foo(a: int, b: string) = nil
foo(1, "test")

proc bar(a: int, b: string) = nil
bar(1, "test")

template foo(a: int, b: string) = bar(a, b)
foo(1, "test")

block:
  proc bar(a: int, b: string) = nil
  template foo(a: int, b: string) = nil
  foo(1, "test")
  bar(1, "test")
  
proc baz =
  proc foo(a: int, b: string) = nil
  proc foo(b: string) =
    template bar(a: int, b: string) = nil
    bar(1, "test")
    
  foo("test")

  block:
    proc foo(b: string) = nil
    foo("test")
    foo(1, "test")

baz()
