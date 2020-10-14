import json, asyncdispatch
block: #6100
  let done = newFuture[int]()
  done.complete(1)

  proc asyncSum: Future[int] {.async.} =
    for _ in 1..1_000_000:
      result += await done

  let res = waitFor asyncSum()
  doAssert(res == 1_000_000)

block: #7985
  proc getData(): Future[JsonNode] {.async.} =
    result = %*{"value": 1}

  type
    MyData = object
      value: BiggestInt

  proc main() {.async.} =
    let data = to(await(getData()), MyData)
    doAssert($data == "(value: 1)")

  waitFor(main())

block: #8399
  proc bar(): Future[string] {.async.} = discard

  proc foo(line: string) {.async.} =
    var res =
      case line[0]
      of '+', '-': @[]
      of '$': (let x = await bar(); @[""])
      else: @[]

    doAssert(res == @[""])

  waitFor foo("$asd")

block: # nkCheckedFieldExpr
  proc bar(): Future[JsonNode] {.async.} =
    return newJInt(5)

  proc foo() {.async.} =
    let n = 10 + (await bar()).num
    doAssert(n == 15)

  waitFor foo()

block: # 12743

  template templ = await sleepAsync 0

  proc prc {.async.} = templ

  waitFor prc()

block: # issue #13899
  proc someConnect() {.async.} =
    await sleepAsync(1)
  proc someClose() {.async.} =
    await sleepAsync(2)
  proc testFooFails(): Future[bool] {.async.} =
    await someConnect()
    defer:
      await someClose()
      result = true
  proc testFooSucceed(): Future[bool] {.async.} =
    try:
      await someConnect()
    finally:
      await someClose()
      result = true
  doAssert waitFor testFooSucceed()
  doAssert waitFor testFooFails()

block: # issue #9313
  doAssert compiles(block:
    proc a() {.async.} =
      echo "Hi"
      quit(0)
  )
