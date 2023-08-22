discard """
  errormsg: "recursive module dependency detected"
  file: "mrecmod.nim"
  line: 1
  disabled: true
"""
# recursive module
import mrecmod
