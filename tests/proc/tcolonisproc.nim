discard """
output: '''
1
2
'''
"""

proc p(a, b: int, c: proc ()) =
  c()

when false:
  # language spec changed:
  p(1, 3):
    echo 1
    echo 3

p(1, 1, proc() =
  echo 1
  echo 2)
