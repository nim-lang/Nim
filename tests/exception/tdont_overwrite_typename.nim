discard """
  targets: "c cpp"
  output: '''Check passed
Check passed'''
"""

# bug #5628

proc checkException(ex: ref Exception) =
  doAssert(ex.name == cstring"ValueError")
  doAssert(ex.msg == "SecondException")
  doAssert(ex.parent != nil)
  doAssert(ex.parent.name == cstring"KeyError")
  doAssert(ex.parent.msg == "FirstException")
  echo "Check passed"

var e: ref Exception
try:
  try:
    raise newException(KeyError, "FirstException")
  except:
    raise newException(ValueError, "SecondException", getCurrentException())
except:
  e = getCurrentException()

try:
  checkException(e) # passes here
  raise e
except ValueError:
  checkException(getCurrentException()) # fails here
