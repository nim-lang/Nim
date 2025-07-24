discard """
  errormsg: "illegal recursion in type 'Foo'"
  line: 8
"""

type
  Kind = enum kA, kB
  Foo = object
    case k: Kind:
    of kA:
      foo: Foo
    of kB:
      discard
