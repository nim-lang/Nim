discard """
cmd: "nim check --hints:off $file"
errormsg: "type 'void' is not allowed"
"""

type
  MyType = object
    a: void
