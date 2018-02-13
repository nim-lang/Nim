discard """
output: 
"""

{.pragma: rtl, cdecl, exportc.}

proc myproc(x, y: int): int {.rtl} =
  discard

#####################

# bug #7216
{.pragma: my_pragma, raises: [].}

doAssert(not compiles(
  block:
    proc test1 {.my_pragma.} =
      raise newException(Exception, "msg")
))