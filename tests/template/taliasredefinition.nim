discard """
  errormsg: "redefinition of 'foo'; previous declaration here: taliasredefinition.nim(6, 10)"
"""

var x = 3
template foo: untyped {.alias.} = x
var y = 4
template foo: untyped {.alias.} = y
