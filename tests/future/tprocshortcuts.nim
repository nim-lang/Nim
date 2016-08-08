discard """
  file: "tprocshortcuts.nim"
  exitcode: 0
"""

proc passTwoAndTwo(f: (int, int) -> int): int =
  f(2, 2)

doAssert passTwoAndTwo((x, y) => x + y) == 4