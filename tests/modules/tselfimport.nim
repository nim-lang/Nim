discard """
  line: 6
  errormsg: "A module cannot import itself"
"""
import strutils as su # guard against regression
import tselfimport #ERROR
echo("Hello World")
