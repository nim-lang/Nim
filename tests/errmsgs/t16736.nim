discard """
  action: reject
  errormsg: "const 'something' cannot be assigned to proc of calling convention 'closure'"
"""
type ProcType = proc()
const something: ProcType = proc() = discard
discard typeof(something)