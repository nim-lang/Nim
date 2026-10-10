discard """
  output: "hi"
"""

# bug #16456
import std/macros

macro bugcheck(body: static NimNode): untyped =
  body

bugcheck(newStmtList())
bugcheck(newCall("echo", newLit"hi"))
