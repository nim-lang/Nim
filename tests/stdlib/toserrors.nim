discard """
  action: compile
"""

import std/oserrors

let x1 = osLastError()
raiseOSError(x1)
echo osErrorMsg(x1)
