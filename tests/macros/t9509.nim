discard """
  nimout: '''
1
1
2
2
'''
"""

# bug #9509: a static param of a macro used in an inner proc
macro foo2(i: static[int]): untyped =
  echo $i
  proc doNothing() =
    echo i
  doNothing()

foo2(1)
foo2(2)
