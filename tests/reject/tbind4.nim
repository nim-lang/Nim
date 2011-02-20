discard """
  file: "tbind4.nim"
  line: 9
  errormsg: "undeclared identifier: \'lastId\'"
"""
# Module B
import mbind4

echo genId() #ERROR_MSG instantiation from here




