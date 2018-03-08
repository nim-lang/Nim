discard """
  file: "tuserpragma2.nim"
  line: 11
  errormsg: "can raise an unlisted exception: ref Exception"
"""

# bug #7216
{.pragma: my_pragma, raises: [].}

proc test1 {.my_pragma.} =
  raise newException(Exception, "msg")
