discard """
targets: "c cpp js"
"""

when defined(c) or defined(cpp):
  {.emit:"""
  const int TEST = 123;
  """.}

when defined(js):
  {.emit:"""
  const TEST = 123;
  """.}

let TEST {.importc, nodecl.}: cint
doAssert TEST == 123
