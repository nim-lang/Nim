discard """
  errormsg: "undeclared identifier: \'global\'"
  file: "tnamspc.nim"
  line: 10
"""
# Test17 - test correct handling of namespaces

import mnamspc1

global = 9 #ERROR
