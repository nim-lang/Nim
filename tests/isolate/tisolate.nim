discard """
  errormsg: "expression cannot be isolated: select(a, b)"
  line: 39
"""

import std / isolation

import json, streams

proc myParseJson(s: Stream; filename: string): JsonNode =
  {.cast(noSideEffect).}:
    result = parseJson(s, filename)


proc f(): seq[int] =
  @[1, 2, 3]

type
  Node = ref object
    x: string

proc g(): Node = nil

proc select(a, b: Node): Node =
  a

proc main =
  discard isolate f()


  discard isolate g()

  discard isolate select(Node(x: "a"), nil)
  discard isolate select(Node(x: "a"), Node(x: "b"))

  discard isolate myParseJson(newFileStream("my.json"), "my.json")

  var a, b: Node
  discard isolate select(a, b)

main()
