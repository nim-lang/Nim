discard """
  output: "yay"
  cmd: "nim c --gc:arc $file"
"""

# bug #15122

import tables

type
  BENodeKind* = enum
    tkEof,
    tkBytes,
    tkList,
    tkDict

  BENode* = object
    case kind: BENodeKind
    of tkBytes: strVal: string
    of tkList: listVal: seq[BENode]
    of tkDict: dictVal*: Table[string, BENode]
    else:
      discard

proc unused(s: string): BENode =
  # bad:
  result = BENode(kind: tkBytes, strVal: "abc")

proc main =
  var data = {
    "examples": {
      "values": BENode(
        kind: tkList,
        listVal: @[BENode(kind: tkBytes, strVal: "test")]
      )
    }.toTable()
  }.toTable()

  # For ARC listVal is empty for some reason
  doAssert data["examples"]["values"].listVal[0].strVal == "test"

main()
echo "yay"
