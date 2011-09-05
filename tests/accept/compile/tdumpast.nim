# Dump the contents of a PNimrodNode

import macros
  
macro dumpAST(n: stmt): stmt = 
  # dump AST as a side-effect and return the inner node
  echo n.prettyPrint
  echo n.toYaml

  result = n[1]
  
dumpAST:
  proc add(x, y: int): int =
    return x + y
  
  proc sub(x, y: int): int = return x - y


