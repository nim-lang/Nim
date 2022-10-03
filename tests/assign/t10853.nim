
discard """
  cmd: "nim check --hints:off $file"
  errormsg: ""
  nimout: '''
t10853.nim(22, 10) Error: cannot unpack '1'
'''
"""











import osproc
var a, b = 0
(a, b) = 1
var c: string
var d:int
var cmd = "ls --nonexistent"
(c, d) = execCmdEx cmd