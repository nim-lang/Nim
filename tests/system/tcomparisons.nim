discard """
  targets: "c cpp js"
"""

template main =
  block: # proc equality
    var prc: proc(): int {.closure.}
    prc = nil
    doAssert prc == nil
    doAssert prc.isNil
    prc = proc(): int =
      result = 123
    doAssert prc != nil
    doAssert not prc.isNil
    doAssert prc == prc
    let prc2 = prc
    doAssert prc == prc2
    doAssert prc2 != nil
    doAssert not prc2.isNil
    doAssert not prc.isNil
    prc = proc(): int =
      result = 456
    doAssert prc != nil
    doAssert not prc.isNil
    doAssert prc != prc2
  block: # iterator equality
    when nimvm: discard # vm does not support closure iterators
    else:
      when not defined(js): # js also does not support closure iterators
        var iter: iterator(): int {.closure.}
        iter = nil
        doAssert iter == nil
        doAssert iter.isNil
        iter = iterator(): int =
          yield 123
        doAssert iter != nil
        doAssert not iter.isNil
        doAssert iter == iter
        let iter2 = iter
        doAssert iter == iter2
        doAssert iter2 != nil
        doAssert not iter2.isNil
        doAssert not iter.isNil
        iter = iterator(): int =
          yield 456
        doAssert iter != nil
        doAssert not iter.isNil
        doAssert iter != iter2

static: main()
main()
