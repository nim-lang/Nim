# test sym digest is computable at compile time

import macros, algorithm

macro testmacro(s: typed{nkSym}): string =
  let s = signaturehash(s) & " - " & symBodyHash(s)
  result = newStrLitNode(s)


# something recursive and/or generic
discard testmacro(testmacro)
discard testmacro(`[]`)
discard testmacro(binarySearch)
discard testmacro(sort)






