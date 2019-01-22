discard """
  exitcode: 0
  output: "ok"
"""

import json, asyncdispatch
block: #6100
  let done = newFuture[int]()
  done.complete(1)

  proc asyncSum: Future[int] {.async.} =
    for _ in 1..10_000_000:
      result += await done

  let res = waitFor asyncSum()
  doAssert(res == 10000000)

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

echo "ok"
