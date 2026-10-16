discard """
  action: compile
  matrix: "--app:lib -d:createNimRtl --threads:on; --app:lib -d:createNimRtl --threads:on --mm:refc"
"""

# An `except` with a type reads the header of the current exception. In a
# module of nimrtl, `nimBorrowCurrentException` is exported rather than
# inlined, so the module saw `Exception` only declared forward, and the C
# compiler rejected the read. The exception must come from another module:
# raising it here would define `Exception` in this one.

import std/strutils

proc isNumber*(s: cstring): bool {.exportc, dynlib.} =
  try:
    discard parseInt($s)
    result = true
  except ValueError:
    result = false
