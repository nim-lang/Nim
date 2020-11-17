discard """
  errmsg: "unhandled exception: cannot find owner of call routine `tmp` from invalid AST node [ERecoverableError]"
  file: ""
"""
import macros

macro foo: untyped = 
  result = newStmtList()
  let tmp = genSym(nskProc, "tmp") # or nskMacro, nskTemplate...
  result.add quote do:
    let bar = `tmp`()
    
foo()