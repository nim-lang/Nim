discard """
  file: "tinvcolonlocation1.nim"
  line: 8
  column: 7
  errormsg: "expected: ':', but got: 'echo'"
"""
try #<- missing ':'
  echo "try"
except:
  echo "except"
finally:
  echo "finally"
