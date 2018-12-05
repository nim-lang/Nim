# feature request #1473
import macros
import strutils
import "tests/assert/testhelper.nim"

block: # parseExpr
  macro test(text: string): untyped =
    try:
      result = parseExpr(text.strVal)
    except ValueError:
      result = newLit getCurrentExceptionMsg()

  const
    valid = 45

  static:
    assertEquals test("valid"), 45 # valid test

    block: # invalid test
      const a = test("foo&&")
      doAssert a.endsWith """
Error: invalid indentation" with:
>foo&&""", a

    block: # bug #2504
      const a = test("\"")
      doAssert a.endsWith """
Error: closing \" expected" with:
>""""

block: # parseStmt
  macro test(text: string): untyped =
    try:
      result = parseStmt(text.strVal)
    except ValueError:
      result = newLit getCurrentExceptionMsg()

  const
    valid = 45

  static:
    assertEquals test("(let a = valid; valid)"), 45 # valid test

    block:
      const a = test("""
let a = 1
 let a2 = 1""")
      doAssert a.endsWith """Error: invalid indentation" with:
>let a = 1
> let a2 = 1"""

when false: # BUG: this shouldn't even compile, see https://github.com/nim-lang/Nim/issues/9918
  block:
    macro fun(): untyped =
      parseStmt("""
  let a1 = 2 # wrong indentation
a1""")
    doAssert fun() == 2
