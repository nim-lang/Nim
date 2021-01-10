discard """
  cmd: "nim check $file"
  errormsg: "range types need to be constructed with '..', '..<' is not supported"
  nimout: '''trangeerror.nim(8, 16) Error: range types need to be constructed with '..', '..<' is not supported
trangeerror.nim(9, 9) Error: range types need to be constructed with '..', '..<' is not supported'''
"""

var x: range[1 ..< 12] = 4
var y: 1..<13 = 12
discard x
discard y
