discard """
  cmd: "nim check --strings:sso --mm:orc --hints:off $file"
  action: "reject"
  nimout: '''
tsso_string_index_var.nim(13, 12) Error: expression 's[0]' is immutable, not 'var'
'''
"""

proc passByVar(c: var char) =
  c = 'x'

var s = "abc"
passByVar(s[0])
