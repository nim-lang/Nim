discard """
  out: '''HELLO WORLD'''
"""

import macros, strutils

emit("echo " & '"' & "hello world".toUpper & '"')
