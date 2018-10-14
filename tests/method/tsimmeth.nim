discard """
  file: "tsimmeth.nim"
  output: "HELLO WORLD!"
"""
# Test method simulation

import strutils

var x = "hello world!".toLowerAscii.toUpperAscii
x.echo()
#OUT HELLO WORLD!



