# Test enums

type
  E = enum a, b, c, x, y, z

var
  en: E
en = a

# Bug #4066
import macros
macro genEnum(): untyped = newNimNode(nnkEnumTy).add(newEmptyNode(), newIdentNode("geItem1"))
type GeneratedEnum = genEnum()
doAssert(type(geItem1) is GeneratedEnum)
