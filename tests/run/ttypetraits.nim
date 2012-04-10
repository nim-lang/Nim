discard """
  msg:    "int\nstring\nTBar[int]"
  output: "int\nstring\nTBar[int]"
"""

import typetraits

proc foo(x) =
  static:
    var t = type(x)
    echo t.name

  echo x.type.name

type
  TBar[U] = object
    x: U

var bar: TBar[int]

foo 10
foo "test"
foo bar

