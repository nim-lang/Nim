discard """
  errormsg: "expected: ':', but got: 'keyword finally'"
  file: "tinvcolonlocation2.nim"
  line: 11
  column: 8
"""
try:
  echo "try"
except #<- missing ':'
  echo "except"
finally:
#<-- error will be here above, at the beginning of finally,
#    since compiler tries to consome echo and part of except
#    expression
  echo "finally"
