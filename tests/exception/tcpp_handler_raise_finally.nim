discard """
  targets: "cpp"
  matrix: "--mm:arc; --mm:orc; --mm:refc"
  output: '''
inner: orig
finally
outer: re:orig
inner-typeless: orig
finally-typeless
outer-typeless: re-tl:orig
no-catch-finally
caught-propagated: prop
'''
"""

# When an `except` handler raises a new exception, the enclosing `finally`
# block must still run before the new exception propagates to the outer
# try.
#
# The C++ backend previously emitted the finally's `catch (...)` as a
# sibling of the user-written catches.  C++ does not allow sibling catches
# to catch each other's throws, so a handler-raised exception bypassed the
# finally entirely.  The fix wraps the inner try/catch sequence in an
# outer try, so any escaping exception (whether from the body or from a
# handler) is captured before the finally runs.

block typed_except:
  try:
    try:
      raise newException(CatchableError, "orig")
    except CatchableError as e:
      echo "inner: ", e.msg
      raise newException(CatchableError, "re:" & e.msg)
    finally:
      echo "finally"
  except CatchableError as outer:
    echo "outer: ", outer.msg

block typeless_except:
  try:
    try:
      raise newException(CatchableError, "orig")
    except:
      let e = getCurrentException()
      echo "inner-typeless: ", e.msg
      raise newException(CatchableError, "re-tl:" & e.msg)
    finally:
      echo "finally-typeless"
  except CatchableError as outer:
    echo "outer-typeless: ", outer.msg

# try/finally without an except: the body's exception must still propagate
# after the finally runs.
block no_catch_finally:
  try:
    try:
      raise newException(CatchableError, "prop")
    finally:
      echo "no-catch-finally"
  except CatchableError as e:
    echo "caught-propagated: ", e.msg
