discard """
  output: "{ b: 2 }"
"""

import jsconsole, jsffi

type
  A = ref object
   b: B

  B = object
    b: int

var a = cast[A](js{})
a.b = B(b: 2)
console.log a.b
