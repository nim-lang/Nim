discard """
  cmd: "nim check $file"
"""

when not defined(gcOrc):
  {.error: "orc".}
