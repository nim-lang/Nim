discard """
  cmd: "nim c --gc:arc $file"
  output: '''
hello
hello
'''
"""

import dmodule

var val = parseMinValue()
if val.kind == minDictionary:
  echo val
