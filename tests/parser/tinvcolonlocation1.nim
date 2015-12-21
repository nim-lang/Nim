discard """
  line: 7
  column: 3
  errormsg: "':' expected"
"""
try #<- missing ':'
  echo "try"
except:
  echo "except"
finally:
  echo "finally"
