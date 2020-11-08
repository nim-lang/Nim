discard """
  errormsg: "has to be used (or discarded)"
  line: 7
"""

proc myProc(name: string): string = "Hello " & name
myProc("Dominik")
