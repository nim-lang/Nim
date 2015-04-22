
import macros

macro match*(s: cstring|string; pos: int; sections: untyped): untyped =
  for sec in sections.children:
    expectKind sec, nnkOfBranch
    expectLen sec, 2
  result = newStmtList()

when isMainModule:
  var input = "the input"
  var pos = 0
  match input, pos:
  of r"[a-zA-Z_]\w+": echo "an identifier"
  of r"\d+": echo "an integer"
  of r".": echo "something else"
