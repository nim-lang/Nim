discard """
  action: "reject"
  nimout: '''
t1566_invalid_indent_missing_equals.nim(12, 3) Error: possible errors:
  * invalid indentation of top level statement
  * missing `=` to implement previous routine
'''
"""

# line 10
proc fn(n: int) {.exportc.}
  echo 1