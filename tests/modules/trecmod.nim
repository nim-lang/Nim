discard """
  file: "mrecmod.nim"
  line: 1
  errormsg: "recursive module dependency detected"
"""
# recursive module
import mrecmod
