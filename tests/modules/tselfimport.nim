discard """
  errormsg: "module 'tselfimport' cannot import itself"
  file: "tselfimport.nim"
  line: 7
"""
import strutils as su # guard against regression
import tselfimport #ERROR
echo("Hello World")
