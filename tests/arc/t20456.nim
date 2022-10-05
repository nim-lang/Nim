discard """
  cmd: "nim check $file"
  action: "compile"
"""

when not defined(gcOrc):
  {.error: "orc".}
