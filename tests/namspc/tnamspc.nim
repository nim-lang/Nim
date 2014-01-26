discard """
  file: "tnamspc.nim"
  line: 10
  errormsg: "undeclared identifier: \'global\'"
"""
# Test17 - test correct handling of namespaces

import mnamspc1

global = 9 #ERROR


