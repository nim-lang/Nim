discard """
  targets: "c cpp"
  disabled: windows
"""
# bug #21116
import std/os

proc p(glob: string) =
  for _ in walkFiles(glob): discard
p("dir/*")
