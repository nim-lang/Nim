discard """
  cmd: '''nim c --compileTime:restricted --hints:off $file'''
  errormsg: "'createDir' refused by --compileTime:restricted"
  line: 11
"""

# R4
import std/os

static:
  createDir("trestricted_created")
