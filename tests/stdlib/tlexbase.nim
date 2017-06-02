discard """
  output: 'true'
"""

import lexbase

proc testLexer(lex: var BaseLexer, input: string) =
  var inputPos = 0
  while lex.buf[lex.bufpos] != EndOfFile:
    assert lex.buf[lex.bufpos] == input[inputPos]
    inc(inputPos)
    if input[inputPos - 1] == '\c' and input[inputPos] == '\l': inc(inputPos)
    case lex.buf[lex.bufpos]
    of '\c': lex.bufpos = lex.handleCR(lex.bufpos)
    of '\l': lex.bufpos = lex.handleLF(lex.bufpos)
    else: inc(lex.bufpos)

when not defined(js):
  import streams
  block streamAsInput:
    let input = "lorem ipsum\l\ldolor\lsit amet\l"
    var lex: BaseLexer
    lex.open(newStringStream(input))
    lex.testLexer(input)

block stringAsInput:
  let input = "lorem ipsum\l\ldolor\lsit amet\l"
  var lex: BaseLexer
  lex.open(input)
  lex.testLexer(input)

block CRLF:
  let input = "lorem ipsum\c\l\c\ldolor\c\lsit amet\c\l"
  var lex: BaseLexer
  lex.open(input)
  lex.testLexer(input)

block smallBufLen:
  let input = "lorem ipsum\l\ldolor\lsit amet\l"
  var lex: BaseLexer
  lex.open(input, bufLen=4)
  lex.testLexer(input)

echo "true"