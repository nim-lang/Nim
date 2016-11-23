discard """
  file: "tselfimport.nim"
  line: 7
  errormsg: "recursive module dependency detected"
"""
import strutils as su # guard against regression
import tselfimport #ERROR
echo("Hello World")

