## Dump a binary NIF (`.bif`) cache artifact as textual NIF, one node per line,
## for inspection and for diffing two artifacts:
##
##     bin/bif2nif <cache>/<module>.t.bif
##
## Build: `nim c -d:release -o:bin/bif2nif tools/bif2nif.nim`.

import std / [os, strutils]
import "../dist/nimony/src/lib/nifcore" except pool
from "../dist/nimony/src/lib" / bif import load, BifModule

proc dump(c: var Cursor; res: var string; depth: int) =
  case c.kind
  of TagLit:
    res.add repeat(' ', depth) & "(" & c.tags.tagName(cursorTagId(c))
    c.into:
      if c.hasMore: res.add "\n"
      var first = true
      while c.hasMore:
        if not first: res.add "\n"
        first = false
        dump(c, res, depth + 1)
    res.add ")"
  of DotToken: res.add repeat(' ', depth) & "."; inc c
  of CharLit: res.add repeat(' ', depth) & "'" & $charLit(c) & "'"; inc c
  of StrLit: res.add repeat(' ', depth) & escape(strVal(c)); inc c
  of IntLit: res.add repeat(' ', depth) & $intVal(c); inc c
  of UIntLit: res.add repeat(' ', depth) & $uintVal(c) & "u"; inc c
  of FloatLit: res.add repeat(' ', depth) & $floatVal(c); inc c
  of Symbol: res.add repeat(' ', depth) & symName(c); inc c
  of SymbolDef: res.add repeat(' ', depth) & ":" & symName(c); inc c
  of Ident: res.add repeat(' ', depth) & strVal(c); inc c
  else: res.add repeat(' ', depth) & "<" & $c.kind & ">"; inc c

proc main() =
  if paramCount() != 1:
    quit "usage: bif2nif <file.bif>"
  var m = load(paramStr(1))
  var c = beginRead(m.buf)
  var res = ""
  while c.hasMore:
    dump(c, res, 0)
    res.add "\n"
  stdout.write res

main()
