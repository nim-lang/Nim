discard """
  file: "readall_echo.nim"
"""
when isMainModule:
  echo(stdin.readAll)
