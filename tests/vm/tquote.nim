discard """
  joinable: false
"""

import std/macros

static:
  discard quote:
    a and b

var x {.compileTime.} : NimNode = 
  quote do:
    echo "xxx"