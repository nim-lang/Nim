discard """
  file: "tinvcolonlocation3.nim"
  line: 12
  column: 7
  errormsg: "expected: ':', but got: 'echo'"
"""
try:
  echo "try"
except:
  echo "except"
finally #<- missing ':'
  echo "finally"
