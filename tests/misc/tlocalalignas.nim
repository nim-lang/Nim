discard """
ccodeCheck: "\\i @'alignas(128) NI myval' .*"
target: "c cpp"
"""

proc myProc() =
  var myval {.alignas(128).}: int = 123
  echo myval

myProc()
