#
#
#           The Nim Compiler
#        (c) Copyright 2026 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Nim's OWN module-suffix, replacing nimony's `gear2/modnames.moduleSuffix`.
##
## nimony's version hashes a path made RELATIVE to `getCurrentDir()` (or the
## shortest search-path-relative form), so the produced suffix depends on the
## current working directory AND the searchPath set. Under `nim ic` the
## DISCOVERY pass (`deps.nim`, in the driver process) and the COMPILE pass
## (`nifgen`/`typekeys`, in a child `nim m` process) can run with different CWDs
## or `--path` sets, so the SAME file hashes to two different suffixes: e.g.
## `std/staticos` became `sta5rk8sn1` at discovery but `sta4c0qxk` at compile, so
## every importer waited forever for a `.s.bif` that was actually written under
## the other name — a cold `nim ic` build (of anything pulling in `std/os`, whose
## `oscommon` does `from std/staticos import PathComponent`) never converged.
##
## Hashing the CANONICAL ABSOLUTE path makes the suffix a pure function of the
## file, identical across every process and call site. The base-name prefix +
## base-36 `uhash` layout is kept byte-for-byte compatible with the old scheme so
## nothing but the hashed string changes.

import std/os
import "../dist/nimony/src/lib" / tinyhashes

const
  PrefixLen = 3 # keep it short: the suffix ends up in every mangled C name
  Base36 = "0123456789abcdefghijklmnopqrstuvwxyz"

proc moduleSuffix*(path: string; searchPaths: openArray[string]): string =
  ## `searchPaths` is accepted for signature-compatibility with the replaced
  ## `modnames.moduleSuffix` but is deliberately IGNORED — the suffix must not
  ## depend on the search-path set or the CWD (see the module doc).
  # Absolute inputs (the norm at every call site: `toFullPath`/`projectFull`)
  # pass straight through `normalizedPath` with no `getCurrentDir` involvement;
  # a stray relative path is made absolute against the CWD only as a fallback.
  var f = path
  if not isAbsolute(f):
    try: f = absolutePath(f)
    except CatchableError: discard
  f = normalizedPath(f)
  let m = splitFile(f).name
  var id = uhash(f)
  result = newStringOfCap(10)
  for i in 0 ..< min(m.len, PrefixLen):
    result.add m[i]
  # base-36 of the hash, low digit first (order is irrelevant for identity).
  while id > 0'u32:
    result.add Base36[int(id mod 36'u32)]
    id = id div 36'u32
