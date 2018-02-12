discard """
  file: "tfinally.nim"
  output: '''came
here
3
msg1
msg2
finally2
finally1
'''
"""
# Test return in try statement:

proc main: int =
  try:
    try:
      return 1
    finally:
      echo("came")
      return 2
  finally:
    echo("here")
    return 3

echo main() #OUT came here 3

#bug 7204
proc nested_finally =
  try:
    raise newException(KeyError, "msg1")
  except KeyError as ex:
    echo ex.msg
    try:
      raise newException(ValueError, "msg2")
    except:
      echo getCurrentExceptionMsg()
    finally:
      echo "finally2"
  finally:
    echo "finally1"

nested_finally()