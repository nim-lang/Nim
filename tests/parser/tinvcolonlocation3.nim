discard """
  line: 11
  column: 3
  errormsg: "':' expected"
"""
try:
  echo "try"
except:
  echo "except"
finally #<- missing ':'
  echo "finally"
