discard """
  cmd: '''nim c --newruntime $file'''
  output: '''OK 3
5 2'''
"""

import strutils, math
import system / ansi_c
import system / allocators

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

let (a, d) = allocCounters()
discard cprintf("%ld %ld\n", a, d)
