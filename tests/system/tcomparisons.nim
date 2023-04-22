template main =
  block: # proc equality
    var prc: proc(): int {.closure.}
    prc = nil
    doAssert prc == nil
    prc = proc(): int =
      result = 123
    doAssert prc != nil
    doAssert prc == prc
    let prc2 = prc
    doAssert prc == prc2
    doAssert prc2 != nil
    prc = proc(): int =
      result = 456
    doAssert prc != nil
    doAssert prc != prc2
  when nimvm: discard # vm does not support closure iterators
  else:
    block: # iterator equality
      var iter: iterator(): int {.closure.}
      iter = nil
      doAssert iter == nil
      iter = iterator(): int =
        yield 123
      doAssert iter != nil
      doAssert iter == iter
      let iter2 = iter
      doAssert iter == iter2
      doAssert iter2 != nil
      iter = iterator(): int =
        yield 456
      doAssert iter != nil
      doAssert iter != iter2

static: main()
main()
