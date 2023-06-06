discard """
  errormsg: "identifier expected, but found '<<0th child missing for nkOpenSymChoice >>'"
"""

# prevent ICE

import macros

macro foo() =
  result = newLetStmt(
    # bad sym choice:
    newNimNode(nnkOpenSymChoice),
    newLit(123))

foo()
