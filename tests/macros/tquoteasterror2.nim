discard """
errormsg: "undeclared identifier: 'a'"
"""
# This test should ensure that accidentally not capturing a symbol
# from the environment triggers a clean undeclared identifier error
# message.

import experimental/quote2

macro fooF(): untyped =
  let a = @[1,2,3,4,5]
  result = quoteAst():
    a

fooF()
