discard """
action: compile
ccodecheck: "\\i !@('#include <string.h>')"
"""

proc createSeq*(a, b: int): seq[int]  {.cdecl, exportc, dynlib} =
  @[a,b,a,b,a]

echo createSeq(42, 5)
