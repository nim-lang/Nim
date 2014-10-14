discard """
  file: "tselfimport.nim"
  line: 6
  errormsg: "A module cannot import itself"
"""
import tselfimport #ERROR
echo("Hello World")

