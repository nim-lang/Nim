discard """
action: "reject"
cmd: "nim check $file"
errormsg: "unhandled exception: (1, 2) Error: invalid character literal [ValueError]"
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
