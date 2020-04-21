discard """
  output: '''
believer Foo is saved:true
believer Bar is saved:true
believer Baz is saved:true
'''
"""

import asyncdispatch

var
  promise = newFuture[bool]()

proc believers(name: string) {.async.} =
  let v = await promise
  echo "believer " & name & " is saved:" & $v

asyncCheck believers("Foo")
asyncCheck believers("Bar")
asyncCheck believers("Baz")

proc savior() {.async.} =
  await sleepAsync(50)
  complete(promise, true)
  await sleepAsync(50) # give enough time to see who was saved

waitFor(savior())
