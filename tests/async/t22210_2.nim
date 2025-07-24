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


proc testFoo2(): Future[ClientResponse] {.async.} =
  var flag = 0
  try:
    let status = await subFoo1()
    doAssert(status == 200)
    let data = await subFoo2()
    result = ClientResponse(status: status, data: data)
  finally:
    inc flag
    await sleepAsync(100)
    inc flag
    await sleepAsync(200)
    inc flag
  doAssert flag == 3

discard waitFor testFoo2()

proc testFoo3(): Future[ClientResponse] {.async.} =
  var flag = 0
  try:
    let status = await subFoo1()
    doAssert(status == 200)
    let data = await subFoo2()
    if false:
      return ClientResponse(status: status, data: data)
  finally:
    inc flag
    await sleepAsync(100)
    inc flag
    await sleepAsync(200)
    inc flag
  doAssert flag == 3

discard waitFor testFoo3()


proc testFoo4(): Future[ClientResponse] {.async.} =
  var flag = 0
  try:
    let status = await subFoo1()
    doAssert(status == 200)
    let data = await subFoo2()
    if status == 200:
      return ClientResponse(status: status, data: data)
    else:
      return ClientResponse()
  finally:
    inc flag
    await sleepAsync(100)
    inc flag
    await sleepAsync(200)
    inc flag
  doAssert flag == 3

discard waitFor testFoo4()
