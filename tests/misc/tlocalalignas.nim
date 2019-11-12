discard """
ccodeCheck: "\\i @'alignas(128) NI myval' .*"
target: "c cpp"
"""

# This is for Azure. The keyword ``alignof`` only exists in ``c++11``
# and newer. On Azure gcc does not default to c++11 yet.
when defined(cpp) and not defined(windows):
  {.passC: "-std=c++11".}

proc myProc() =
  var myval {.alignas(128).}: int = 123
  echo myval

myProc()
