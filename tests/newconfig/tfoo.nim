discard """
  cmd: "nim default --hint:cc:off --hint:cc $file"
  output: '''hello world! 0.5 true'''
  nimout: '''[NimScript] exec: gcc -v'''
"""

when not defined(definedefine):
  {.fatal: "wrong nim script configuration".}

import math, mfriends

discard gen[int]()
echo "hello world! ", ln 2.0, " ", compileOption("opt", "speed")
