discard """
  action: compile
  cmd: "nim check $file" 
"""

type AC_WINCTRL_Fields* = distinct uint8

type AC_STATUSA_WSTATE0* {.pure.} = enum
  ABOVE = 0x0,
  INSIDE = 0x1,
  BELOW = 0x2,

type AC_WINCTRL_WINTSEL0* {.pure.} = enum
  ABOVE = 0x0,
  INSIDE = 0x1,
  BELOW = 0x2,
  OUTSIDE = 0x3,

proc write*(WINTSEL0: AC_WINCTRL_WINTSEL0 = ABOVE) =
  discard
