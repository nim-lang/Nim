discard """
  targets: "c cpp js"
"""

import cstrutils


block tcstrutils:
  let s = cstring "abcdef"
  doAssert s.startsWith("a")
  doAssert not s.startsWith("b")
  doAssert s.endsWith("f")
  doAssert not s.endsWith("a")

  let a = cstring "abracadabra"
  doAssert a.startsWith("abra")
  doAssert not a.startsWith("bra")
  doAssert a.endsWith("abra")
  doAssert not a.endsWith("dab")

  doAssert cmpIgnoreCase(cstring "FooBar", "foobar") == 0
  doAssert cmpIgnoreCase(cstring "bar", "Foo") < 0
  doAssert cmpIgnoreCase(cstring "Foo5", "foo4") > 0

  doAssert cmpIgnoreStyle(cstring "foo_bar", "FooBar") == 0
  doAssert cmpIgnoreStyle(cstring "foo_bar_5", "FooBar4") > 0

  doAssert cmpIgnoreCase(cstring "", cstring "") == 0
  doAssert cmpIgnoreCase(cstring "", cstring "Hello") < 0
  doAssert cmpIgnoreCase(cstring "wind", cstring "") > 0
