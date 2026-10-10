discard """
  action: "compile"
"""

# https://github.com/nim-lang/Nim/issues/17630
# A concept that references itself in a proc signature
# should not cause infinite recursion / stack overflow

type
  A = concept
    proc test(x: Self, y: A)

proc test(x: int, y: int) = discard

discard (int is A)
