discard """
  file: "tselfimport.nim"
  line: 7
  errormsg: "A module cannot import itself"
"""
import strutils as su # guard against regression
import tselfimport #ERROR
echo("Hello World")

