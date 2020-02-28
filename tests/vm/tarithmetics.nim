# https://github.com/nim-lang/Nim/issues/13513

template testAll(isSemFold: bool) =
  block:
    template test(T) =
      proc fun(): T {.gensym.} =
        when isSemFold:
          high(T) +% 1
        else:
          let a = high(T)
          a +% 1
      const a1 = fun()
      let a2 = fun()
      doAssert a1 <= high(T)
      doAssert $a1 == $a2
      doAssert a1 == a2
    test(int8)
    test(int16)
    test(int32)

testAll(true) # will call semfold.nim `of mAddU:`
testAll(false) # will call vm.nim `of opcNarrowU:`
