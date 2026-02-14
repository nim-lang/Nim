discard """
  output: '''hello
3
2
1
0'''
"""

import parseutils

var w = ""
discard parseIdent("hello world", w)
echo w

for i in countdown(w.len - 2, 0):
  echo i
