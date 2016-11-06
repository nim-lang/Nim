discard """
  file: "tmacroerrorproc.nim"
  line: 13
  errormsg: "Expected a node of kind nnkCharLit, got nnkCommand"
"""
# issue #4915
import macros

macro mixer(n: typed): untyped =
  expectKind(n, nnkCharLit)
  
mixer:
  echo "owh"