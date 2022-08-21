discard """
  disabled: "windows" # no sigsetjmp() there
  matrix: "-d:nimStdSetjmp; -d:nimSigSetjmp; -d:nimRawSetjmp; -d:nimBuiltinSetjmp"
  output: '''

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
"""

echo ""

proc no_exception =
  try:
    echo "BEFORE"

  except:
    echo "EXCEPT"
    raise

  finally:
    echo "FINALLY"

try: no_exception()
except: echo "RECOVER"

echo ""

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

echo ""

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

block: #10417
  proc moo() {.noreturn.} = discard

  let bar =
    try:
      1
    except:
      moo()

  doAssert(bar == 1)

# Make sure the VM handles the exceptions correctly
block:
  proc fun1(): seq[int] =
    try:
      try:
        raise newException(ValueError, "xx")
      except:
        doAssert("xx" == getCurrentExceptionMsg())
        raise newException(KeyError, "yy")
    except:
      doAssert("yy" == getCurrentExceptionMsg())
      result.add(1212)
    try:
      try:
        raise newException(AssertionDefect, "a")
      finally:
        result.add(42)
    except AssertionDefect:
      result.add(99)
    finally:
      result.add(10)
    result.add(4)
    result.add(0)
    try:
      result.add(1)
    except KeyError:
      result.add(-1)
    except ValueError:
      result.add(-1)
    except IndexDefect:
      result.add(2)
    except:
      result.add(3)

    try:
      try:
        result.add(1)
        return
      except:
        result.add(-1)
      finally:
        result.add(2)
    except KeyError:
      doAssert(false)
    finally:
      result.add(3)

  let x1 = fun1()
  const x2 = fun1()
  doAssert(x1 == x2)
