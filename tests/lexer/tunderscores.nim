discard """
  errormsg: "invalid token: trailing underscore"
  file: "tunderscores.nim"
  line: 8
"""
# Bug #502670

var ef_ = 3  #ERROR_MSG invalid token: _
var a__b = 1
var c___d = 2
echo(ab, cd, ef_)
