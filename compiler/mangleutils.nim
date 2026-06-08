import std/strutils
import ast, modulegraphs

proc mangle*(name: string): string =
  result = newStringOfCap(name.len)
  var start = 0
  if name[0] in Digits:
    result.add("X" & name[0])
    start = 1
  var requiresUnderscore = false
  template special(x) =
    result.add x
    requiresUnderscore = true
  for i in start..<name.len:
    let c = name[i]
    case c
    of 'a'..'z', '0'..'9', 'A'..'Z':
      result.add(c)
    of '_':
      # we generate names like 'foo_9' for scope disambiguations and so
      # disallow this here:
      if i > 0 and i < name.len-1 and name[i+1] in Digits:
        discard
      else:
        result.add(c)
    of '$': special "dollar"
    of '%': special "percent"
    of '&': special "amp"
    of '^': special "roof"
    of '!': special "emark"
    of '?': special "qmark"
    of '*': special "star"
    of '+': special "plus"
    of '-': special "minus"
    of '/': special "slash"
    of '\\': special "backslash"
    of '=': special "eq"
    of '<': special "lt"
    of '>': special "gt"
    of '~': special "tilde"
    of ':': special "colon"
    of '.': special "dot"
    of '@': special "at"
    of '|': special "bar"
    else:
      result.add("X" & toHex(ord(c), 2))
      requiresUnderscore = true
  if requiresUnderscore:
    result.add "_"

proc mangleParamExt*(s: PSym): string =
  result = "_p"
  result.addInt s.position

proc mangleProcNameExt*(graph: ModuleGraph, s: PSym): string =
  result = "__"
  # Under incremental compilation the main module is registered at its source
  # file index, but its symbols are keyed by the NIF-suffix file index, which has
  # no `ifaces` slot. Only the main module has this gap (dependencies are
  # registered at their suffix index), so omitting the unique name for it stays
  # collision-free: the mangled base name plus `disamb` already disambiguate.
  if s.itemId.module >= 0 and s.itemId.module < graph.ifaces.len:
    result.add graph.ifaces[s.itemId.module].uniqueName
  result.add "_u"
  # Use `disamb` rather than `itemId.item`: under incremental compilation a
  # symbol loaded from a NIF file gets a fresh, load-order-dependent `itemId.item`
  # (from the per-module symbol counter), which is neither stable across the
  # processes that compile vs. use a module nor guaranteed distinct from another
  # loaded symbol's. `disamb` is assigned deterministically per (module, name)
  # and, together with the already-prepended mangled name, yields a unique and
  # stable C identifier.
  result.addInt s.disamb
