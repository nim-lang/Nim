discard """
  cmd: '''nim c --newruntime $file'''
  output: '''OK 2
4 1'''
"""

import strutils, math
import system / ansi_c
import core / allocators

proc mainA =
  var e: owned(ref ValueError)
  new(e)
  e.msg = "message"
  raise e

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

echo "OK ", ok

let (a, d) = allocCounters()
discard cprintf("%ld %ld\n", a, d)
