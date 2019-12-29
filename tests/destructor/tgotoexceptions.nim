discard """
  output: '''
msg1
msg2
finally2
finally1
begin
one iteration!
caught!
except1
finally1
caught! 2'''
  cmd: "nim c --gc:arc --exceptions:goto $file"
"""

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

proc doraise =
  raise newException(ValueError, "gah")

proc main =
  while true:
    try:
      echo "begin"
      doraise()
    finally:
      echo "one ", "iteration!"

try:
  main()
except:
  echo "caught!"

when true:
  proc p =
    try:
      raise newException(Exception, "Hello")
    except:
      echo "except1"
      raise
    finally:
      echo "finally1"

  try:
    p()
  except:
    echo "caught! 2"
