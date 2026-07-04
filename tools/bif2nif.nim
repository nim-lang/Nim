## bif2nif — translate a binary NIF (`.bif`) cache back into textual NIF.
##
## `bif` (see `dist/nimony/src/lib/bif.nim`) stores a `nifcore` `TokenBuf`
## verbatim (token block + the four pools + a trailing symbol index) for fast,
## compact IC caches. This tool reloads that buffer and re-serializes it through
## the normal nifcore text writer (`toModuleString`), giving a human-readable,
## diff-able `.nif` — useful for inspecting/debugging bif caches and as a building
## block wherever a textual view of a binary cache is needed.
##
## Because `bif.load` mints FRESH pools (the format invariant — token words embed
## pool ids that only reproduce when interned from id 1), the reload is exact and
## the text output is token-identical to the buffer that was stored.
##
## Usage:
##   bif2nif <in.bif> [out.nif] [--suffix:<dotted>]
## With no `out.nif`, the text is written to stdout. The module's dotted suffix
## (used by the writer for symbol-suffix compression and the `(.nif27)` header)
## defaults to `"." & <input file stem>`, mirroring the `.s.nif` naming the IC
## backend uses; override it with `--suffix:`.
##
## Build:  nim c --path:dist/nimony/src/lib tools/bif2nif.nim

import std / [os, strutils]
import bif              # load / BifModule  (re-exports nifcore types)
import nifcoreparse     # toModuleString

proc usage() =
  stderr.writeLine "usage: bif2nif <in.bif> [out.nif] [--suffix:<dotted>]"
  quit 1

proc main =
  var inPath = ""
  var outPath = ""
  var suffix = ""
  var haveSuffix = false
  for i in 1 .. paramCount():
    let a = paramStr(i)
    if a.startsWith("--suffix:"):
      suffix = a["--suffix:".len .. ^1]
      haveSuffix = true
    elif a == "-h" or a == "--help":
      usage()
    elif inPath.len == 0:
      inPath = a
    elif outPath.len == 0:
      outPath = a
    else:
      usage()

  if inPath.len == 0: usage()
  if not fileExists(inPath):
    stderr.writeLine "bif2nif: file not found: " & inPath
    quit 1

  # Default the dotted module suffix to the input stem (e.g. `sys6npxts.bif` →
  # `.sys6npxts`), matching how the IC backend names its `<suffix>.s.nif`.
  if not haveSuffix:
    suffix = "." & splitFile(inPath).name

  var m = bif.load(inPath)
  # `m.buf` is move-only; pass the field directly (no copy) to the writer.
  let text = toModuleString(m.buf, suffix)

  if outPath.len == 0:
    stdout.write text
  else:
    writeFile(outPath, text)
    stderr.writeLine "bif2nif: wrote " & outPath & " (" & $text.len & " bytes)"

main()
