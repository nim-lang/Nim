discard """
  file: "tparseopt.nim"
  output: '''
parseopt
first round
kind: cmdLongOption	key:val  --  left:
second round
kind: cmdLongOption	key:val  --  left:
kind: cmdLongOption	key:val  --  debug:3
kind: cmdShortOption	key:val  --  l:4
kind: cmdShortOption	key:val  --  r:2
parseopt2
first round
kind: cmdLongOption	key:val  --  left:
second round
kind: cmdLongOption	key:val  --  left:
kind: cmdLongOption	key:val  --  debug:3
kind: cmdShortOption	key:val  --  l:4
kind: cmdShortOption	key:val  --  r:2'''
"""
from parseopt import nil
from parseopt2 import nil


block:
    echo "parseopt"
    for kind, key, val in parseopt.getopt():
      echo "kind: ", kind, "\tkey:val  --  ", key, ":", val

    # pass custom cmdline arguments
    echo "first round"
    var argv = "--left --debug:3 -l=4 -r:2"
    var p = parseopt.initOptParser(argv)
    for kind, key, val in parseopt.getopt(p):
      echo "kind: ", kind, "\tkey:val  --  ", key, ":", val
      break
    # reset getopt iterator and check arguments are returned correctly.
    echo "second round"
    for kind, key, val in parseopt.getopt(p):
      echo "kind: ", kind, "\tkey:val  --  ", key, ":", val

block:
    echo "parseopt2"
    for kind, key, val in parseopt2.getopt():
      echo "kind: ", kind, "\tkey:val  --  ", key, ":", val

    # pass custom cmdline arguments
    echo "first round"
    var argv: seq[string] = @["--left", "--debug:3", "-l=4", "-r:2"]
    var p = parseopt2.initOptParser(argv)
    for kind, key, val in parseopt2.getopt(p):
      echo "kind: ", kind, "\tkey:val  --  ", key, ":", val
      break
    # reset getopt iterator and check arguments are returned correctly.
    echo "second round"
    for kind, key, val in parseopt2.getopt(p):
      echo "kind: ", kind, "\tkey:val  --  ", key, ":", val
