# Test numeric literals and handling of minus symbol

import std/macros
import strutils
import mlexerutils

const one = 1
const minusOne = `-`(one)

# check when a minus (-) is a negative sign for a literal

doAssert -1 == minusOne:
  "unable to parse a spaced-prefixed negative int"

doAssert lispReprStr(-1) == """(IntLit -1)""":
  "failed to include minus sign when lexing integer literal"

doAssert -1.0'f64 == minusOne.float64:
  "unable to parse a spaced-prefixed negative float"

doAssert lispReprStr(-1.000'f64) == """(Float64Lit -1.0)""":
  "failed to include minus sign lexing float literal preceded by left paren"

doAssert lispReprStr( -1.000'f64) == """(Float64Lit -1.0)""":
  "failed to include minus sign lexing float literal preceded by a space"

doAssert [-1].contains(minusOne):
  "unable to handle negatives after square bracket"

doAssert lispReprStr([-1]) == """(Bracket (IntLit -1))""":
  "failed to include minus sign lexing int literal preceded by left bracket"

doAssert (-1, 2)[0] == minusOne:
  "unable to handle negatives after parenthesis"

doAssert lispReprStr((-1, 2)) == """(Par (IntLit -1) (IntLit 2))""":
  "failed to include minus sign lexing int literal after parenthesis"

proc x(): int =
  var a = 1;-1  # the -1 should act as the return value

doAssert x() == minusOne:
  "unable to handle negatives after semi-colon"

# check when a minus (-) is an unary op

doAssert -one == minusOne:
  "unable to a negative prior to identifier"

# check when a minus (-) is a a subtraction op

doAssert 4-1 == 3:
  "unable to handle subtraction sans surrounding spaces with a numeric literal"

doAssert 4-one == 3:
  "unable to handle subtraction sans surrounding spaces with an identifier"

doAssert 4 - 1 == 3:
  "unable to handle subtraction with surrounding spaces with a numeric literal"

doAssert 4 - one == 3:
  "unable to handle subtraction with surrounding spaces with an identifier"

# border cases that *should* generate compiler errors

assertAST dedent """
  StmtList
    Asgn
      Ident "x"
      Command
        IntLit 4
        IntLit -1""":
  x = 4 -1

assertAST dedent """
  StmtList
    VarSection
      IdentDefs
        Ident "x"
        Ident "uint"
        IntLit -1""":
  var x: uint = -1
