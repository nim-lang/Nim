discard """
  outputsub: '''Error: invalid indentation 45'''
"""

# feature request #1473
import macros

macro test(text: string): expr =
  try:
    result = parseExpr(text.strVal)
  except ValueError:
    result = newLit getCurrentExceptionMsg()

const
  valid = 45
  a = test("foo&&")
  b = test("valid")

echo a, " ", b
