#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Plugin support for the Nim compiler. Right now plugins
## need to be built with the compiler only: plugins using
## DLLs or the FFI will not work.

import ast, semdata, idents

type
  Transformation* = proc (c: PContext; n: PNode): PNode {.nimcall.}
  Plugin* = tuple
    package, module, fn: string
    t: Transformation

proc pluginMatches*(ic: IdentCache; p: Plugin; s: PSym): bool =
  if s.name.id != ic.getIdent(p.fn).id:
    return false
  let module = s.skipGenericOwner
  if module == nil or module.kind != skModule or
      module.name.id != ic.getIdent(p.module).id:
    return false
  let package = module.owner
  if package == nil or package.kind != skPackage or
      package.name.id != ic.getIdent(p.package).id:
    return false
  return true
