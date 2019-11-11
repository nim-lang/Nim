discard """
  output: "threw exception"
  nimout: '''
I
AM
GROOT
'''
"""
import streams

try:
  var fs = openFileStream("shouldneverexist.txt")
except IoError:
  echo "threw exception"

static:
  var s = newStringStream("I\nAM\nGROOT")
  for line in s.lines:
    echo line
  s.close
