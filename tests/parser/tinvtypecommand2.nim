discard """
  errormsg: "invalid indentation"
  line: 10
  column: 5
"""

type
  Foo = call x, y, z:
      abc
    do:
        def
