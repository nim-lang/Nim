discard """
  output: '''
came
here
3
msg1
msg2
finally2
finally1
-----------
except1
finally1
except2
finally2
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

echo "-----------"
#bug 7414
try:
  try:
    raise newException(Exception, "Hello")
  except:
    echo "except1"
    raise
  finally:
    echo "finally1"
except:
  echo "except2"
finally:
  echo "finally2"
