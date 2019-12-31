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
caught! 2
BEFORE
FINALLY
BEFORE
EXCEPT
FINALLY
RECOVER
BEFORE
EXCEPT: IOError: hi
FINALLY
'''
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


proc noException =
  try:
    echo "BEFORE"

  except:
    echo "EXCEPT"
    raise

  finally:
    echo "FINALLY"

try: noException()
except: echo "RECOVER"

proc reraise_in_except =
  try:
    echo "BEFORE"
    raise newException(IOError, "")

  except IOError:
    echo "EXCEPT"
    raise

  finally:
    echo "FINALLY"

try: reraise_in_except()
except: echo "RECOVER"

proc return_in_except =
  try:
    echo "BEFORE"
    raise newException(IOError, "hi")

  except:
    echo "EXCEPT: ", getCurrentException().name, ": ", getCurrentExceptionMsg()
    return

  finally:
    echo "FINALLY"

try: return_in_except()
except: echo "RECOVER"
