discard """
  errormsg: "unhandled exception"
  file: ""
  matrix: "--mm:orc"
"""

# bug #24521: static walkDir(checkDir=true) should raise OSError when the
# directory doesn't exist. Previously the checkDir flag was dropped by the
# nimvm/weirdTarget branch which forwards to the staticWalkDir vmop.
import std/os

static:
  for k, p in walkDir("nonexistentdirectory", checkDir = true):
    discard
