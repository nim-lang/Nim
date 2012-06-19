discard """
  output: '''
BEFORE
FINALLY

BEFORE
EXCEPT
FINALLY
RECOVER

BEFORE
EXCEPT
FINALLY
'''
"""

echo ""

proc no_expcetion =
  try:
    echo "BEFORE"

  except:
    echo "EXCEPT"
    raise

  finally:
    echo "FINALLY"

try: no_expcetion()
except: echo "RECOVER"

echo ""

proc reraise_in_except =
  try:
    echo "BEFORE"
    raise newException(EIO, "")

  except EIO:
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
    raise newException(EIO, "")

  except:
    echo "EXCEPT"
    return

  finally:
    echo "FINALLY"

try: return_in_except()
except: echo "RECOVER"

