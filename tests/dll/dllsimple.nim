discard """
  file: tdllgen.nim
"""
proc test() {.exportc.} =
  echo("Hello World!")
