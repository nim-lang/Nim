discard """
  errormsg: "expression expected, but found 'keyword do'"
  line: 10
  column: 1
"""

type
  Foo = call x, y, z:
    abc
do:
    def
