discard """
errormsg: "ordinal type expected"
line: 10
"""

# https://github.com/nim-lang/Nim/pull/9909#issuecomment-445519287

type
  E = enum
    myVal = 80.9
