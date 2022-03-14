discard """
  output: "x == 45ugh"
"""

import std/assertions

template myAssert(cond: untyped) =
  when 3 <= 3:
    let c = cond.astToStr
    if not cond:
      echo c, "ugh"

var x = 454
myAssert(x == 45)

