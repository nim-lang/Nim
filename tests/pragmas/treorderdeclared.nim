discard """
output:'''false'''
"""

{.experimental: "codeReordering".}

proc x() =
  echo(declared(foo))

var foo = 4

x() # "false", the same as it would be with code reordering OFF
