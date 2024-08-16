import std/macros


template myPragma(x: int) {.pragma.}

type
  A = object
    x: int64

  B {.myPragma(sizeof(A)).} = object

doAssert B.getCustomPragmaVal(myPragma) == 8