discard """
  cmd: '''nim c --compileTime:restricted --hints:off $file'''
  errormsg: "'putEnv' refused by --compileTime:restricted"
  line: 11
"""

# R4: C compiler processes inherit the environment (e.g. `LD_PRELOAD`).
import std/envvars

static:
  putEnv("NIM_TRESTRICTED", "1")
