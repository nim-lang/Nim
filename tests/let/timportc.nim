discard """
  exitcode: 0
  output: "42"
"""

{.emit: "const int TEST = 42;".}

let TEST {.importc, nodecl.}: cint

echo TEST
