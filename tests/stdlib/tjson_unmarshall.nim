discard """
  output: '''
Original: (kind: P, pChildren: @[(kind: Text, textStr: "mychild"), (kind: Br)])
jsonNode: {"kind":"P","pChildren":[{"kind":"Text","textStr":"mychild"},{"kind":"Br"}]}
Reversed: (kind: P, pChildren: @[(kind: Text, textStr: "mychild"), (kind: Br)])
'''
"""

import json

type
  ContentNodeKind* = enum
    P,
    Br,
    Text,
  ContentNode* = object
    case kind*: ContentNodeKind
    of P: pChildren*: seq[ContentNode]
    of Br: nil
    of Text: textStr*: string

let mynode = ContentNode(kind: P, pChildren: @[
  ContentNode(kind: Text, textStr: "mychild"),
  ContentNode(kind: Br)
])
 
echo "Original: " & $mynode

let jsonNode = %*mynode
echo "jsonNode: " & $jsonNode
echo "Reversed: " & $jsonNode.to(ContentNode)
