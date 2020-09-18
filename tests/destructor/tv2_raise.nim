discard """
  valgrind: true
  cmd: '''nim c -d:nimAllocStats --newruntime $file'''
  output: '''OK 3
(allocCount: 7, deallocCount: 4)'''
"""

import strutils, math
import system / ansi_c

proc mainA =
  try:
    var e: owned(ref ValueError)
    new(e)
    e.msg = "message"
    raise e
  except Exception as e:
    raise


proc main =
  raise newException(ValueError, "argh")

var ok = 0
try:
  mainA()
except ValueError:
  inc ok
except:
  discard

try:
  main()
except ValueError:
  inc ok
except:
  discard

#  bug #11577

proc newError*: owned(ref Exception) {.noinline.} =
  new(result)

proc mainC =
  raise newError()

try:
  mainC()
except:
  inc ok

echo "OK ", ok
echo getAllocStats()
