discard """
output: '''
iteration: 1
iteration: 2
iteration: 3
iteration: 4
async done
iteration: 5
'''
"""

import asyncdispatch, times

var done = false
proc somethingAsync() {.async.} =
  yield sleepAsync 500
  echo "async done"
  done = true
  
asyncCheck somethingAsync()
var count = 0
let s0 = now()
while not done:
  count += 1
  drain 100
  echo "iteration: ", count 
  echo "ms: ", (now() - s0).inMilliseconds
