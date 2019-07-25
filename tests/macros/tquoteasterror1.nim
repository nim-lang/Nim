discard """
errormsg: "type mismatch: got <seq[int]> but expected 'NimNode = ref NimNodeObj'"
"""

# This test should ensure that a captured symbol that is not of type
# `NimNode` trigger an error message. Automatically lifting symbols is
# unsafe.

import experimental/quote2

macro fooF(): untyped =
  let a = @[1,2,3,4,5]
  result = quoteAst(a):
    a
