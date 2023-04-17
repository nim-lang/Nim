
{.experimental: "flexibleOptionalParams".}

# https://github.com/nim-lang/RFCs/issues/405

template main =
  template fn1(a = 1, b = 2, body): auto = (a, b, astToStr(body))
  let a1 = fn1(10, 20):
    foo
  doAssert a1 == (10, 20, "\nfoo")

  template fn2(a = 1, b = 2, body): auto = (a, b, astToStr(body))
  let a2 = fn2(a = 10): foo
  doAssert a2 == (10, 2, "\nfoo")
  let a2b = fn2(b = 20): foo
  doAssert a2b == (1, 20, "\nfoo")

  template fn3(x: int, a = 1, b = 2, body): auto = (a, b, astToStr(body))
  let a3 = fn3(3, 10, 20): foo
  doAssert a3 == (10, 20, "\nfoo")
  let a3b = fn3(3, a = 10): foo
  doAssert a3b == (10, 2, "\nfoo")

  template fn4(x: int, y: int, body): auto = (x, y, astToStr(body))
  let a4 = fn4(1, 2): foo
  doAssert a4 == (1, 2, "\nfoo")

  template fn5(x = 1, y = 2, body: untyped = 3): auto = (x, y, astToStr(body))
  doAssert compiles(fn5(1, 2, foo))
  doAssert not compiles(fn5(1, foo))

  block:
    # with an overload
    var witness = 0
    template fn6() = discard
    template fn6(procname: string, body: untyped): untyped = witness.inc
    fn6("abc"): discard
    assert witness == 1

  block:
    # with overloads
    var witness = 0
    template fn6() = discard
    template fn6(a: int) = discard
    template fn6(procname: string, body: untyped): untyped = witness.inc
    fn6("abc"): discard
    assert witness == 1

    template fn6(b = 1.5, body: untyped): untyped = witness.inc
    fn6(1.3): discard
    assert witness == 2

  block:
    var witness = 0
    template fn6(a: int) = discard
    template fn6(a: string) = discard
    template fn6(ignore: string, b = 1.5, body: untyped): untyped = witness.inc
    fn6(""):
      foobar1
      foobar2
    doAssert witness == 1
    fn6(""): discard
    doAssert witness == 2

  block: # multi block args
    template fn8(a = 1, b = 2, body1: untyped, body2: untyped): auto = (a, b, astToStr(body1), astToStr(body2))
    let a1 = fn8():
      foobar1
      foobar2
    do:
      foobar3
      foobar4
    doAssert a1 == (1, 2, "\nfoobar1\nfoobar2", "\nfoobar3\nfoobar4")

    let a2 = fn8(b = 20):
      foobar1
      foobar2
    do:
      foobar3
      foobar4
    doAssert a2 == (1, 20, "\nfoobar1\nfoobar2", "\nfoobar3\nfoobar4")
  
  block: # issue #19015
    template hi(a: untyped, b: varargs[untyped]): untyped =
      a

    var worked = false
    hi:
      worked = true
    doAssert worked
    worked = false
    hi(doAssert(not worked)):
      doesntCompile
    hi(doAssert(not worked), doesntCompile, againDoesntCompile):
      definitelyDoesntCompile

    template hi2(a: bool, b: untyped, c: varargs[untyped]): untyped =
      b
      doAssert a

    hi2 worked:
      worked = true
    doAssert worked
    hi2 worked, doAssert(worked):
      doesntCompile
    hi2 worked, doAssert(worked), doesntCompile, againDoesntCompile:
      definitelyDoesntCompile
    hi2 worked, doAssert(worked), againDoesntCompile:
      definitelyDoesntCompile

static: main()
main()
