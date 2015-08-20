discard """
  cmd: "nim default $file"
  output: '''hello world!'''
  msg: '''[NimScript] exec: gcc -v'''
"""

echo "hello world!"
