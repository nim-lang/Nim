#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Plugin support for the Nim compiler. Right now there are no plugins and they
## need to be build with the compiler, no DLL support.

import ast, semdata, idents

type
  Transformation* = proc (c: PContext; n: PNode): PNode {.nimcall.}
  Plugin = ref object
    fn, module, package: PIdent
    t: Transformation
    next: Plugin

proc pluginMatches(p: Plugin; s: PSym): bool =
  if s.name.id != p.fn.id: return false
  let module = s.owner
  if module == nil or module.kind != skModule or
      module.name.id != p.module.id: return false
  let package = module.owner
  if package == nil or package.kind != skPackage or
      package.name.id != p.package.id: return false
  return true

var head: Plugin

proc getPlugin*(fn: PSym): Transformation =
  var it = head
  while it != nil:
    if pluginMatches(it, fn): return it.t
    it = it.next

proc registerPlugin*(package, module, fn: string; t: Transformation) =
  let oldHead = head
  head = Plugin(fn: getIdent(fn), module: getIdent(module),
                 package: getIdent(package), t: t, next: oldHead)
