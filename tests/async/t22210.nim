discard """
output: '''
stage 1
stage 2
stage 3
(status: 200, data: "SOMEDATA")
'''
"""

import std/asyncdispatch


# bug #22210
type
  ClientResponse = object
    status*: int
    data*: string

proc subFoo1(): Future[int] {.async.} =
  await sleepAsync(100)
  return 200

proc subFoo2(): Future[string] {.async.} =
  await sleepAsync(100)
  return "SOMEDATA"

proc testFoo(): Future[ClientResponse] {.async.} =
  try:
    let status = await subFoo1()
    doAssert(status == 200)
    let data = await subFoo2()
    return ClientResponse(status: status, data: data)
  finally:
    echo "stage 1"
    await sleepAsync(100)
    echo "stage 2"
    await sleepAsync(200)
    echo "stage 3"

when isMainModule:
  echo waitFor testFoo()