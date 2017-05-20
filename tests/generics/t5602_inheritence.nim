discard """
  output: "seq[float]\n0"
"""

# https://github.com/nim-lang/Nim/issues/5602

import typetraits

type
  Foo[T] = object of RootObj
  Bar[T] = object of Foo[seq[T]]

proc p[T](f: Foo[T]): T =
  echo T.name

var s: Bar[float]
echo p(s).len # the bug was: p(s) should return seq[float], but returns float instead

