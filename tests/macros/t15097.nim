discard """
  errormsg: "attempting to call undeclared routine: 'tmp'"
  line: 10
"""

import std/macros

macro foo: untyped =
  let tmp = genSym(nskProc, "tmp")
  result = quote do:
    let bar = `tmp`()

foo()
