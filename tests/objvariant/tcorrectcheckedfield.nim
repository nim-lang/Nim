discard """
  matrix: "; --warning[ProveField]:on --warningAsError[ProveField]:on; --experimental:strictCaseObjects"
"""

block: # issue #24021
  type
    FooKind = enum
      a
      b
    BiggerEnum = enum b1, b2, b3, b4, b5, b6, b7, b8, b9, b10
    Foo = object
      case kind: FooKind
      of a: discard
      else:
        z: BiggerEnum

  proc p(foo: Foo, val: int) =
    case foo.kind
    of a:
      discard
    else:
      discard foo.z


# bug #22791
type Foo = object
  case a: bool
  of false:
    discard
  of true:
    case b: bool
    of false:
      discard
    of true:
      c: bool

const f = Foo(a: true, b: true, c: true)
case f.a
of true:
  case f.b
  of true:
    echo f.c
  else: discard
else: discard