discard """
  nimout: '''
proc `hi@procName`(`a@param`: int) =
  discard
var `x:y`: int
var `a$$b`: string
var normalIdent: int
var `mysym'`'gensym1`: int
'''
  joinable: false
"""

# Test that the renderer properly quotes identifiers with special characters
# Bug #19735: AST renderer fails to escape/quote special symbols in identifiers

import macros

macro testSpecialIdents(): untyped =
  # Test @ symbol in identifiers
  let procName = ident("hi@procName")
  let paramName = ident("a@param")

  # Test : symbol
  let colonIdent = ident("x:y")

  # Test $ symbol
  let dollarIdent = ident("a$b")

  # Test normal identifier (should NOT be quoted)
  let normalIdent = ident("normalIdent")

  result = quote do:
    proc `procName`(`paramName`: int) = discard
    var `colonIdent`: int
    var `dollarIdent`: string
    var `normalIdent`: int

  echo result.repr

testSpecialIdents()

# Test gensym'd identifiers (backtick in name should be escaped as '`')
macro testGensym(): untyped =
  result = quote do:
    var mysym: int

  echo result.repr

testGensym()
