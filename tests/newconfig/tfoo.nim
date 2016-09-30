discard """
  cmd: "nim default $file"
  output: '''hello world! 0.5'''
  msg: '''[NimScript] exec: gcc -v'''
"""

when not defined(definedefine):
  {.fatal: "wrong nim script configuration".}

import math

echo "hello world! ", ln 2.0
