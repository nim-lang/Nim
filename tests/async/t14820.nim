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
  yield sleepAsync 1000
  echo "async done"
  done = true
  
asyncCheck somethingAsync()
var count = 0
while not done:
  count += 1
  drain 200
  echo "iteration: ", count 
