discard """
  cmd: "nim default $file"
  output: '''hello world!'''
  msg: '''[NimScript] exec: gcc -v'''
"""

when not defined(definedefine):
  {.fatal: "wrong nim script configuration".}

echo "hello world!"
