discard """
  line: 10
  errormsg: '''expression 'open(f, "arg.txt", fmRead, -1)' is of type 'bool' and has to be discarded'''
"""

proc p =
  var f: File
  echo "hi"

  open(f, "arg.txt")

p()
