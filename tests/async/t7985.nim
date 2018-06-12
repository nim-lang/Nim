discard """
  file: "t7985.nim"
  exitcode: 0
  output: "(value: 1)"
"""
import json, asyncdispatch

proc getData(): Future[JsonNode] {.async.} =
  result = %*{"value": 1}

type
  MyData = object
    value: BiggestInt

proc main() {.async.} =
  let data = to(await(getData()), MyData)
  echo data

waitFor(main())
