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
  # The disambiguator comes first and the module suffix LAST, so the suffix is
  # a strippable trailing token: content-addressed cross-module merging chops
  # everything from the final `__` to recover a mint-site-independent name.
  if s.itemId.isBackendMinted:
    # A symbol minted during IC codegen (`idGeneratorForBackend`): its idgen
    # starts with an EMPTY per-name disamb table, so its `disamb` restarts at 0
    # and collides with same-named sem-time symbols loaded from NIFs (two
    # `=destroy` hooks both mangling to `_u2` → "conflicting types for ..." in
    # the generated C). Most such symbols never cross a process boundary (nifc
    # lifts, emits and compiles them in one run), so the per-module-unique
    # item id is a safe and deterministic discriminator; the `_c` marker keeps
    # the namespace disjoint from `_u<disamb>`.
    result = "_c"
    if (s.disamb and HookDisambBit) != 0'i32:
      # EXCEPTION: a backend-minted sym whose `disamb` is content-derived
      # (setHookDisamb gave it HookDisambBit) — e.g. the `rttiDestroy` wrapper —
      # DOES cross process boundaries: its C name is baked into the type's RTTI
      # table, which is emit-everywhere and merge-deduped, so one process's
      # `_c<item>` (a per-process backend counter) ends up referenced while the
      # wrapper is defined with another's → undefined at link (`rttiDestroy_c23`).
      # The content-derived disamb is stable across processes; use it.
      result.addInt s.disamb
    else:
      result.addInt s.itemId.item
  else:
    result = "_u"
    # Use `disamb` rather than `itemId.item`: under incremental compilation a
    # symbol loaded from a NIF file gets a fresh, load-order-dependent `itemId.item`
    # (from the per-module symbol counter), which is neither stable across the
    # processes that compile vs. use a module nor guaranteed distinct from another
    # loaded symbol's. `disamb` is assigned deterministically per (module, name)
    # and, together with the already-prepended mangled name, yields a unique and
    # stable C identifier.
    result.addInt s.disamb
  result.add "__"
  result.add graph.ifaces[s.itemId.module].uniqueName
