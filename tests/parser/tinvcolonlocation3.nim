discard """
  file: "tinvcolonlocation3.nim"
  line: 12
  column: 3
  errormsg: "':' expected"
"""
try:
  echo "try"
except:
  echo "except"
finally #<- missing ':'
  echo "finally"
