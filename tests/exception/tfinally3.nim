discard """
  outputsub: '''
false
Within finally->try
'''
  exitCode: 1
"""
# Test break in try statement:

proc main: bool =
  while true:
    try:
      return true
    finally:
      break
  return false

echo main() #OUT false

# bug #5871
try:
  raise newException(Exception, "First")
finally:
  try:
    raise newException(Exception, "Within finally->try")
  except:
    echo getCurrentExceptionMsg()
