discard """
  output: '''true
true'''
"""

import pegs

template optPeg{peg(pattern)}(pattern: string{lit}): Peg =
  var gl {.global, gensym.} = peg(pattern)
  gl

echo match("(a b c)", peg"'(' @ ')'")
echo match("W_HI_Le", peg"\y 'while'")
