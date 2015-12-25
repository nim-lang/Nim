discard """
  output: "HELLO WORLD!"
"""
# Test method simulation

import strutils

var x = "hello world!".toLower.toUpper
x.echo()
#OUT HELLO WORLD!
