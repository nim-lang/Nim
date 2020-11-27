discard """
  output: '''
finally handler 8
do not duplicate this one
'''
"""

# bug #15243

import asyncdispatch

proc f() {.async.} =
  try:
    while true:
      try:
        await sleepAsync(400)
        break
      finally:
        var localHere = 8
        echo "finally handler ", localHere
  finally:
    echo "do not duplicate this one"

when isMainModule:
  waitFor f()
