discard """
  cmd: "nim c --mm:orc $file"
  output: ""
"""
import ./t25341_aux/a, ./t25341_aux/b
a()
b()
