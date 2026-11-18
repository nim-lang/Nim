from ../tfrom_import {.cyclic.} import fa, A

type
  Color* = enum red, green
  B* = object
    x*: int
    a*: ref A

proc fb*(): int = fa() + 1
converter toInt*(c: Color): int = ord(c) + 10
proc hidden*(): int = 7
