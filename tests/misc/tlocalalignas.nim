discard """
ccodeCheck: "\\i @'alignas(128) myval;' .*"
"""

proc myProc() =
  var myval {.alignas(128).}: int = 123
  echo myval

myProc()
