# test sym digest is computable at compile time

import macros, algorithm
import md5

macro testmacro(s: typed{nkSym}): string =
  let s = getMD5(signaturehash(s) & " - " & symBodyHash(s))
  result = newStrLitNode(s)

macro testmacro(s: typed{nkOpenSymChoice|nkClosedSymChoice}): string =
  var str = ""
  for sym in s:
    str &= symBodyHash(sym)
  result = newStrLitNode(getMD5(str))

# something recursive and/or generic
discard testmacro(testmacro)
discard testmacro(`[]`)
discard testmacro(binarySearch)
discard testmacro(sort)
