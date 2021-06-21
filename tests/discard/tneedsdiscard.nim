discard """
  errormsg: '''expression 'open(f, "arg.txt", fmRead, -1)' is of type 'bool' and has to be used (or discarded); start of expression here: tneedsdiscard.nim(7, 3)'''
  line: 10
"""

proc p =
  var f: File
  echo "hi"

  open(f, "arg.txt")

p()
