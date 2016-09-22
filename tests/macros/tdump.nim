discard """
  output: '''x = 10
x + y = 30
'''
"""

import future

let
  x = 10
  y = 20
dump x
dump(x + y)