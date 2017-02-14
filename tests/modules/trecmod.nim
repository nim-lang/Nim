discard """
  file: "mrecmod.nim"
  line: 1
  errormsg: "recursive module dependency detected"
  disabled: true
"""
# recursive module
import mrecmod
