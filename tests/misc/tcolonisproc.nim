discard """
output: '''
1
2
'''
"""

proc p(a, b: int, c: proc ()) =
  c()

p(1, 1, proc() =
  echo 1
  echo 2)
