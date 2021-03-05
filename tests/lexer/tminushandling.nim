# Test tkStrNumLit

import std/macros
import strutils

macro assertAST(expected: string, struct: untyped): untyped =
  var ast = newLit(struct.treeRepr)
  result = quote do:
    if `ast` != `expected`:
      echo "Got:"
      echo `ast`.indent(2)
      echo "Expected:"
      echo `expected`.indent(2)
      raise newException(ValueError, "Failed to lex properly")

const one = 1
const minusOne = `-`(one)

# check when a minus (-) is a negative sign for a literal

doAssert -1 == minusOne:
  "unable to parse a spaced-prefixed negative int"

assertAST dedent """
  StmtList
    IntLit -1""":
  -1

doAssert -1.0'f64 == minusOne.float64:
  "unable to parse a spaced-prefixed negative float"

assertAST dedent """
  StmtList
    Float64Lit -1.0""":
  -1.0'f64

doAssert [-1].contains(minusOne):
  "unable to handle negatives after square bracket"

assertAST dedent """
  StmtList
    Bracket
      IntLit -1""":
  [-1]

doAssert (-1, 2)[0] == minusOne:
  "unable to handle negatives after parenthesis"

assertAST dedent """
  StmtList
    Par
      IntLit -1
      IntLit 2""":
  (-1, 2)

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

# border cases that *should* generate a compiler errors

assertAST dedent """
  StmtList
    Asgn
      Ident "x"
      Command
        IntLit 4
        IntLit -1""":
  x = 4 -1
