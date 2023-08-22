discard """
  action: run
  cmd: "nim c --gc:arc $file"
"""

proc f1() {.noreturn.} = raise newException(CatchableError, "")

proc f2(y: int): int =
  if y != 0:
    y
  else:
    f1()

doAssert f2(5) == 5
doAssertRaises(CatchableError):
  discard f2(0)
