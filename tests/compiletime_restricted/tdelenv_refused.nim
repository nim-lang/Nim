discard """
  cmd: '''nim c --compileTime:restricted --hints:off $file'''
  errormsg: "'delEnv' refused by --compileTime:restricted"
  line: 11
"""

# R4
import std/envvars

static:
  delEnv("NIM_TRESTRICTED_UNSET")
