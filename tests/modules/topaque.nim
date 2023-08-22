discard """
  errormsg: "undeclared field: \'buffer\'"
  file: "topaque.nim"
  line: 16
"""
# Test the new opaque types

import
  mopaque

var
  L: TLexer

L.filename = "ha"
L.line = 34
L.buffer[0] = '\0' #ERROR_MSG undeclared field: 'buffer'
