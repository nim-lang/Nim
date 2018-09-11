discard """
  line: 7
  errormsg: "has to be discarded"
"""

proc myProc(name: string): string = "Hello " & name
myProc("Dominik")