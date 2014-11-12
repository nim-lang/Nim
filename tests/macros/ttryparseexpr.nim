discard """
  outputsub: '''Error: invalid indentation'''
"""

# feature request #1473
import macros

macro test(text: string): expr =
  try:
    result = parseExpr(text.strVal)
  except ValueError:
    result = newLit getCurrentExceptionMsg()

const
  a = test("foo&&")

echo a
