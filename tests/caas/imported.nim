discard """
  file: "imported.nim"
"""

proc `+++`*(a,b: string): string =
  return a & "  " & b
