discard """
  errormsg: "field access outside of valid case branch: x.x"
  line: 25
"""

{.experimental: "strictCaseObjects".}

type
  Foo = object
    case b: bool
    of false:
      s: string
    of true:
      x: int

var x = Foo(b: true, x: 4)
case x.b
of true:
  echo x.x
of false:
  echo "no"

case x.b
of false:
  echo x.x
of true:
  echo "no"
