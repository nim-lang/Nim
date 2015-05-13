discard """
  file: "tinvcolonlocation1.nim"
  line: 8
  column: 3
  errormsg: "':' expected"
"""
try #<- missing ':'
  echo "try"
except:
  echo "except"
finally:
  echo "finally"
