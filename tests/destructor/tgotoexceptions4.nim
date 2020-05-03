discard """
  cmd: "nim c --gc:arc --exceptions:goto $file"
  output: '''caught in gun
caught in fun
caughtsome msgMyExcept
in finally
caught1
123
123'''
"""

when true:
  # bug #13070
  type MyExcept = object of CatchableError
  proc gun() =
    try:
      raise newException(MyExcept, "some msg")
    except Exception as eab:
      echo "caught in gun"
      raise eab

  proc fun() =
    try:
      gun()
    except Exception as e:
      echo "caught in fun"
      echo("caught", e.msg, e.name)
    finally:
      echo "in finally"
  fun()

when true:
  # bug #13072
  type MyExceptB = object of CatchableError
  proc gunB() =
    raise newException(MyExceptB, "some msg")
  proc funB() =
    try:
      gunB()
    except CatchableError:
      echo "caught1"
  funB()

# bug #13782

import strutils
var n = 123

try: n = parseInt("xxx")
except: discard

echo n

proc sameTestButForLocalVar =
  var n = 123
  try: n = parseInt("xxx")
  except: discard
  echo n

sameTestButForLocalVar()
