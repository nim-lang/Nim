discard """
  output: '''A
B
X
inner finally
Y
outer finally
msg1
msg2
finally2
finally1
true'''
  cmd: "nim c --gc:arc $file"
"""

# bug #13668

proc main =
  try:
    try:
      raise newException(IOError, "IOError")

    except:
      echo "A"
      raise newException(CatchableError, "CatchableError")

  except:
    echo "B"
    #discard

proc mainB =
  try:
    try:
      raise newException(IOError, "IOError")

    except:
      echo "X"
      raise newException(CatchableError, "CatchableError")
    finally:
      echo "inner finally"

  except:
    echo "Y"
    #discard
  finally:
    echo "outer finally"

main()
mainB()

when true:
  #bug 7204
  proc nested_finally =
    try:
      raise newException(KeyError, "msg1")
    except KeyError as ex:
      echo ex.msg
      try:
        # pop exception
        raise newException(ValueError, "msg2") # push: exception stack (1 entry)
      except:
        echo getCurrentExceptionMsg()
        # pop exception (except)
      finally:
        echo "finally2"
      # pop exception (except KeyError as ex)
    finally:
      echo "finally1"

  nested_finally()

# bug #14925
proc test(b: bool) =
  echo b

test(try: true except: false)
