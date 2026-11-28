discard """
  joinable: false
"""

import std/[assertions, os, osproc, strutils, tables, tempfiles, times]
from "../../compiler/icmodnames" import moduleSuffix

const nim = getCurrentCompilerExe()
let dir = expandFilename(createTempDir("nim_ic_backend_config_", ""))
let cache = dir / "cache"
let exe = dir / "app".addFileExt(ExeExt)
let src = dir / "main.nim"

proc build(flags: seq[string]; expected: string): string =
  let cmd = @[nim, "c", "--ic:on", "--skipUserCfg", "--hints:off", "--warnings:off",
    "--nimcache:" & cache, "--out:" & exe] & flags & @[src]
  let compiled = execCmdEx(quoteShellCommand(cmd))
  doAssert compiled.exitCode == 0, compiled.output
  let run = execCmdEx(quoteShell(exe))
  doAssert run.exitCode == 0 and run.output.strip == expected, run.output
  result = readFile(cache / "ic_link_args.txt").splitLines[0]

proc snapshot(path: string; endings: openArray[string]): Table[string, Time] =
  for file in walkDirRec(path):
    for ending in endings:
      if file.endsWith(ending):
        result[file] = getLastModificationTime(file)
        break
  doAssert result.len > 0, path & " has no matching artifacts"

try:
  createDir(dir / "extra")
  writeFile(dir / "provider.nim", """
proc number*(): cint =
  {.emit: "`result` = CHOICE;".}
""")
  writeFile(src, """
import provider
when defined(higher):
  {.passC: "-DCHOICE=27".}
else:
  {.passC: "-DCHOICE=12".}
echo number()
""")
  let backend = build(@[], "12")
  let lower = snapshot(backend, [".t.bif", ".lower.reads"])
  let cg = snapshot(backend, [".nim.c.nif", ".cg.reads"])
  let emit = snapshot(backend, [".nim.c", ".emit.reads"])
  let objects = snapshot(backend, [".o", ".obj"])
  let executable = getLastModificationTime(exe)
  doAssert build(@["-d:unused", "--path:" & (dir / "extra")], "12") == backend
  doAssert snapshot(backend, [".t.bif", ".lower.reads"]) == lower
  doAssert snapshot(backend, [".nim.c.nif", ".cg.reads"]) == cg
  doAssert snapshot(backend, [".nim.c", ".emit.reads"]) == emit
  doAssert snapshot(backend, [".o", ".obj"]) == objects
  doAssert getLastModificationTime(exe) == executable

  # This option is read by emit, but not by the earlier backend stages.
  doAssert build(@["-d:icCPartBytes=1000"], "12") == backend
  doAssert snapshot(backend, [".t.bif", ".lower.reads"]) == lower
  doAssert snapshot(backend, [".nim.c.nif", ".cg.reads"]) == cg
  let firstEmit = snapshot(backend, [".nim.c", ".emit.reads"])
  doAssert firstEmit != emit
  discard build(@["-d:icCPartBytes=2000"], "12")
  doAssert snapshot(backend, [".nim.c", ".emit.reads"]) != firstEmit
  doAssert snapshot(backend, [".nim.c.nif", ".cg.reads"]) == cg
  let cgBefore = snapshot(backend, [".nim.c.nif", ".cg.reads"])
  doAssert build(@["-d:icNoCDce"], "12") == backend
  doAssert snapshot(backend, [".t.bif", ".lower.reads"]) == lower
  doAssert snapshot(backend, [".nim.c.nif", ".cg.reads"]) != cgBefore

  # A truncated stage observation must be treated as a cache miss.
  let damaged = backend / (moduleSuffix(src, []) & ".cg.reads")
  doAssert fileExists(damaged)
  writeFile(damaged, "(configreads")
  discard build(@["-d:icNoCDce", "-d:unused"], "12")
  doAssert readFile(damaged) != "(configreads"

  # passC in the main module must recompile the dependency's generated C.
  discard build(@["-d:icBatchSize=3", "-d:higher"], "27")
  discard build(@[], "12")

  # Loading --compile in a validation worker must leave the shared object
  # intact, including when its flags came from a module pragma.
  writeFile(dir / "number.c", "int value(void) { return CHOICE; }\n")
  writeFile(src, """
{.passC: "-DCHOICE=35".}
proc value(): cint {.importc.}
echo value()
""")
  let external = @["--compile:" & (dir / "number.c")]
  let externalBackend = build(external, "35")
  let externalObjects = snapshot(externalBackend, [".o", ".obj"])
  doAssert build(external & @["-d:unused"], "35") == externalBackend
  doAssert snapshot(externalBackend, [".o", ".obj"]) == externalObjects
  writeFile(dir / "number.c", "int value(void) { return CHOICE + 1; }\n")
  discard build(external, "36")

  # The literal --compile argument stays the same while --path selects the
  # native source file. Revisit both providers in the same backend workspace.
  let first = dir / "first"
  let second = dir / "second"
  createDir(first)
  createDir(second)
  writeFile(first / "picked.c", "int value(void) { return 41; }\n")
  writeFile(second / "picked.c", "int value(void) { return 42; }\n")
  let pickSecond = @["--path:" & first, "--path:" & second, "--compile:picked.c"]
  let pickFirst = @["--path:" & second, "--path:" & first, "--compile:picked.c"]
  let picked = build(pickSecond, "42")
  doAssert build(pickFirst, "41") == picked
  doAssert build(pickSecond, "42") == picked

  # A known build timestamp can be validated like any other observation.
  writeFile(src, "proc stamp(): string = CompileDate & \" \" & CompileTime\necho stamp()\n")
  putEnv("SOURCE_DATE_EPOCH", "0")
  discard build(@[], "1970-01-01 00:00:00")
  let dated = snapshot(backend, [".reads", ".t.bif", ".o", ".obj"])
  discard build(@["-d:unused"], "1970-01-01 00:00:00")
  doAssert snapshot(backend, [".reads", ".t.bif", ".o", ".obj"]) == dated
  putEnv("SOURCE_DATE_EPOCH", "86401")
  discard build(@["-d:anotherUnused"], "1970-01-02 00:00:01")
finally:
  removeDir(dir)
