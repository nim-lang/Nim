discard """
targets: "c cpp js"
"""

when defined(c) or defined(cpp):
  {.emit:"""
  const int TEST1 = 123;
  #define TEST2 321
  """.}

when defined(js):
  {.emit:"""
  const TEST1 = 123;
  const TEST2 = 321; // JS doesn't have macros, so we just duplicate
  """.}

let
  TEST0 = 1
  TEST1 {.importc, nodecl.}: cint
  TEST2 {.importc, nodecl.}: cint

doAssert TEST0 == 1
doAssert TEST1 == 123
doAssert TEST2 == 321
