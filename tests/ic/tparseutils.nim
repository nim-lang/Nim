discard """
  output: '''hello'''
"""

import parseutils

var w = ""
discard parseIdent("hello world", w)
echo w

