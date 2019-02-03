discard """
  action: run
"""

proc fun1(): seq[int] =
  var p = 0
  proc moo() = raise newException(ValueError, "ee")
  proc qoo() =
    try: moo()
    finally: inc p
  try: qoo()
  except:
    doAssert("ee" == getCurrentExceptionMsg())
    result.add(p)
  finally: result.add(21)
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
      raise newException(AssertionError, "a")
    finally:
      result.add(42)
  except AssertionError:
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
  except IndexError:
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
