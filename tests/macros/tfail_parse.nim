discard """
action: "reject"
cmd: "nim check $file"
errormsg: "..${/}..${/}lib${/}core${/}macros.nim(577, 29) Error: expected expression, but got multiple statements [ValueError]"
file: "macros.nim"
"""

import macros
static:
  discard parseStmt("'")
  discard parseExpr("'")
  discard parseExpr("""
proc foo()
proc foo() = discard
""")
