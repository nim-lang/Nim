discard """
errormsg: "ordinal type expected; given: string"
line: 10
"""

# https://github.com/nim-lang/Nim/issues/9908

type
  X = enum
    a = ("a", "b")
