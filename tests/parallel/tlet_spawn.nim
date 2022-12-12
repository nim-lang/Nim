discard """
output: '''
done999 999
'''
"""

import std/[threadpool, os]

proc foo(): int = 999

# test that the disjoint checker deals with 'a = spawn f(); g = spawn f()':

proc main =
  parallel:
    let f = spawn foo()
    let b = spawn foo()
  echo "done", f, " ", b

main()

# bug #13781
proc thread(): string =
  os.sleep(1000)
  return "ok"

var fv = spawn thread()
sync()
doAssert ^fv == "ok"
