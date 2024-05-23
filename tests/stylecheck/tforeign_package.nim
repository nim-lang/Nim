discard """
  matrix: "--errorMax:0 --styleCheck:error"
  action: compile
"""

import foreign_package/foreign_package

# This call tests that:
#   - an instantiation of a generic in a foreign package doesn't raise errors
#     when the generic body contains:
#     - definition and usage violations
#     - builtin pragma usage violations
#     - user pragma usage violations
#   - definition violations in foreign packages are ignored
#   - usage violations in foreign packages are ignored
genericProc[int]()
