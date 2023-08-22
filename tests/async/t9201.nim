discard """
  exitcode: 0
"""

# Derived from issue #9201
import asyncdispatch, macros

macro newAsyncProc(name: untyped): untyped =
  expectKind name, nnkStrLit
  let pName = genSym(nskProc, name.strVal)
  result = getAst async quote do:
    proc `pName`() = discard

newAsyncProc("hello")
