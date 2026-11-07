discard """
action: reject
errormsg: "invalid indentation"
"""

# bug #13842

type TTypeKind* = enum
    tyNone, tyBool, tyChar, tyNil, tyString

proc toNkLit*(a: TTypeKind): int =
  case a
  of tyNil: 1
  of tyChar: 2
  of tyString: 3, 
  else: 4
