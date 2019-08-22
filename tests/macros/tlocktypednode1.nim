discard """
errormsg: "typechecked nodes may not be modified"
"""

import macros

macro doSomething(arg: typed): untyped =
  echo arg.treeREpr
  result = arg
  result.add newCall(bindSym"echo", newLit(1))

doSomething((echo(1); echo(2)))
