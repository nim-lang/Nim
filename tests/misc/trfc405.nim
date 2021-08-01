# https://github.com/nim-lang/RFCs/issues/405

# template main =
proc main =
  block:
    template fn(a = 1, b = 2, body): auto = (a, b, astToStr(body))
    let a1 = fn(10, 20):
      foo
    doAssert a1 == (10, 20, "\nfoo")

    template fn2(a = 1, b = 2, body) = echo (a, b, astToStr(body))
    fn2(a = 10): foo

    # fn2(a = 10):
    #   foo

    # let a2 = fn(a = 10):
    #   foo
    # echo a2
  #   fn(b = 20): foo

  # block:
  #   template fn(x: int, a = 1, b = 2, body) = echo (a, b, astToStr(body))
  #   fn(3, 10, 20): # works
  #     foo
  #   {.define(nimCompilerDebug).}
  #   fn(3, a = 10): foo
  #   fn(3, b = 20): foo
  #   fn(3, b = 20):
  #     foo1
  #     foo2

  # block:
  #   template fn(x: int, y: int, body) = echo (x, y, astToStr(body))
  #   fn(3): foo

static: main()
main()
