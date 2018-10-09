#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Include file that imports all plugins that are active.

import
  ".." / [pluginsupport, idents, ast], locals, itersgen

const
  plugins: array[2, Plugin] = [
    ("stdlib", "system", "iterToProc", iterToProcImpl),
    ("stdlib", "system", "locals", semLocals)
  ]

proc getPlugin*(ic: IdentCache; fn: PSym): Transformation =
  for p in plugins:
    if pluginMatches(ic, p, fn): return p.t
  return nil
