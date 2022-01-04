discard """
  output: "ntWhitespace"
"""

# bug #3357

type NodeType* = enum
  ntWhitespace

type TokenType* = enum
  ttWhitespace

proc enumTable*[A, B, C](a: openArray[tuple[key: A, val: B]], ret: typedesc[C]): C =
  for item in a:
    result[item.key] = item.val

const tokenTypeToNodeType = {
  ttWhitespace: ntWhitespace,
}.enumTable(array[ttWhitespace..ttWhitespace, NodeType])

echo tokenTypeToNodeType[ttWhitespace]
