discard """
  cmd: "nim check $file"
  action: "reject"
  errormsg: "type mismatch: got <string> but expected 'int'"
"""

# `nim check` used to crash on this after the first error
# bug #1691
type
  Foo = ref object of Foo

let afterwards: int = "not an int"
