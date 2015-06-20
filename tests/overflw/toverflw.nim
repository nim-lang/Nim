discard """
  file: "toverflw.nim"
  output: "the computation overflowed"
"""
# Tests nim's ability to detect overflows

{.push overflowChecks: on.}

var
  a, b: int
a = high(int)
b = -2
try:
  writeLine(stdout, b - a)
except OverflowError:
  writeLine(stdout, "the computation overflowed")

{.pop.} # overflow check
#OUT the computation overflowed


