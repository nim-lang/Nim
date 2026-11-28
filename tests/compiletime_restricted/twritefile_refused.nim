discard """
  cmd: '''nim c --compileTime:restricted --hints:off $file'''
  errormsg: "'writeFile' refused by --compileTime:restricted"
  line: 9
"""

# R4
static:
  writeFile("trestricted_written.txt", "x")
