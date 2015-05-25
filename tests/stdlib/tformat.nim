discard """
  file: "tformat.nim"
  output: "Hi Andreas! How do you feel, Rumpf?"
"""
# Tests the new format proc (including the & and &= operators)

import strutils

echo("Hi $1! How do you feel, $2?\N" % ["Andreas", "Rumpf"])
#OUT Hi Andreas! How do you feel, Rumpf?


