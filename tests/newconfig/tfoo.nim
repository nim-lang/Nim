discard """
  cmd: "nim default $file"
  output: '''hello world! 0.5'''
  nimout: '''[NimScript] exec: gcc -v'''
"""

when not defined(definedefine):
  {.fatal: "wrong nim script configuration".}

import math, mfriends

discard gen[int]()
echo "hello world! ", ln 2.0
