discard """
  output: '''
index 5 not in 0 .. 2
index 5 not in 0 .. 2
'''
"""

var x = @[1, 2, 3]

try:
  echo x[5]
except IndexError:
  echo getCurrentExceptionMsg()
except:
  doAssert false

try:
  x[5] = 8
except IndexError:
  echo getCurrentExceptionMsg()
except:
  doAssert false
