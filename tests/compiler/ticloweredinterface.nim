discard """
  joinable: false
"""

import std/[assertions, os, osproc, strutils, tempfiles]
import "../../dist/nimony/src/lib/nifcore"
from "../../dist/nimony/src/lib/bif" import load

type Interface = object
  present: bool
  count: int
  entries: seq[string]

proc tagIs(cur: Cursor; name: string): bool =
  cur.tags.tagName(cursorTagId(cur)) == name

proc interfaces(path: string): array[bool, Interface] =
  var artifact = load(path)
  var cur = beginRead(artifact.buf)
  cur.loopInto:
    if cur.kind == TagLit and
        (tagIs(cur, "interface") or tagIs(cur, "hiddeninterface")):
      let hidden = tagIs(cur, "hiddeninterface")
      doAssert not result[hidden].present
      result[hidden].present = true
      cur.into:
        doAssert cur.kind == IntLit
        result[hidden].count = intVal(cur).int
        skip cur
        while cur.hasMore:
          if cur.kind == Symbol:
            result[hidden].entries.add symName(cur)
            skip cur
          else:
            doAssert cur.kind == TagLit and tagIs(cur, "reexpmod")
            var alias, suffix: string
            cur.into:
              doAssert cur.kind == StrLit
              alias = strVal(cur)
              skip cur
              doAssert cur.kind == StrLit
              suffix = strVal(cur)
              skip cur
            doAssert alias.len > 0 and suffix.len > 0
            result[hidden].entries.add "alias:" & alias & ":" & suffix
      doAssert result[hidden].entries.len == result[hidden].count
    else:
      skip cur
  doAssert result[false].present and result[true].present

let dir = createTempDir("nim_ic_lowered_interface_", "")
try:
  writeFile(dir / "definitions.nim", """
import std/macros
macro declarations(): untyped =
  result = newStmtList()
  for i in 0..<40:
    result.add parseStmt("type Tag" & $i & "* = distinct int")
    result.add parseStmt("proc choose*(x: Tag" & $i & "): int = " & $i)
    result.add parseStmt("proc privateOverloadedNameNeverUsed(x: Tag" & $i & "): int = " & $i)
declarations()
""")
  writeFile(dir / "facade.nim", """
import definitions as longReexportedModuleAlias
import definitions as secondReexportedModuleAlias
export longReexportedModuleAlias, secondReexportedModuleAlias
""")
  let source = dir / "main.nim"
  writeFile(source, """
import facade
echo longReexportedModuleAlias.choose(Tag12(0))
""")
  let cache = dir / "nc"
  let binary = dir / "prog".addFileExt(ExeExt)
  let built = execCmdEx(quoteShellCommand([getCurrentCompilerExe(), "ic",
    "--hints:off", "--warnings:off", "--nimcache:" & cache, "--out:" & binary, source]))
  doAssert built.exitCode == 0, built.output
  let executed = execCmdEx(quoteShell(binary))
  doAssert executed.exitCode == 0 and executed.output.strip == "12", executed.output

  var checked, privateOverloads, aliases: int
  for semantic in walkFiles(cache / "*.s.bif"):
    let lowered = semantic[0 ..< semantic.len - ".s.bif".len] & ".t.bif"
    if fileExists(lowered):
      let original = interfaces(semantic)
      # Compare the actual on-disk sequences, including symbols never demanded
      # by codegen. Reading these names through an eager-only pool accessor can
      # silently copy empty names from the new lazy BIF pools.
      doAssert interfaces(lowered) == original, semantic
      inc checked
      for entry in original[true].entries:
        if entry.startsWith("privateOverloadedNameNeverUsed."): inc privateOverloads
      for entry in original[false].entries:
        if entry.startsWith("alias:longReexportedModuleAlias:") or
            entry.startsWith("alias:secondReexportedModuleAlias:"):
          inc aliases
  doAssert checked >= 3
  doAssert privateOverloads == 40
  doAssert aliases == 2
finally:
  removeDir(dir)
