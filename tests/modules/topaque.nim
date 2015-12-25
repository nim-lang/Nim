discard """
  line: 15
  errormsg: "undeclared field: \'buffer\'"
"""
# Test the new opaque types

import
  mopaque

var
  L: TLexer

L.filename = "ha"
L.line = 34
L.buffer[0] = '\0' #ERROR_MSG undeclared field: 'buffer'
