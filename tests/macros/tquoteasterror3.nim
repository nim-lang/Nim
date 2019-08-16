discard """
exitcode: 1
outputsub: '''
tquoteasterror3.nim(18)  tquoteasterror3
'''
"""

# Test that lineinfo is set correct. This is tested by causing an
# overflow in the generated code. The stacktrace should point into the
# code from the quoteAst body.

import macros

macro foobar() =
  result = quoteAst:
    var tmp = 1
    for x in 0 ..< 100:
      tmp *= 3

foobar()
