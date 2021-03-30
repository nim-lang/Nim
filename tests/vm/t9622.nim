discard """
  targets: "c cpp"
  matrix: "--gc:refc; --gc:arc"
"""

type
  GlobNodeKind = enum
    LiteralIdent,
    Group

  GlobNode = object
    case kind: GlobNodeKind
    of LiteralIdent:
      value: string
    of Group:
      values: seq[string]

  PathSegment = object
    children: seq[GlobNode]

  GlobPattern = seq[PathSegment]

proc parseImpl(): GlobPattern =
  if result.len == 0:
    result.add PathSegment()
  result[^1].children.add GlobNode(kind: LiteralIdent)

block:
  const pattern = parseImpl()
  doAssert $pattern == """@[(children: @[(kind: LiteralIdent, value: "")])]"""
