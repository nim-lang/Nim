discard """
  joinable: false
"""

import std/[assertions, os, osproc, sha1, streams, strutils, tables, tempfiles]
from "../../compiler/icmodnames" import moduleSuffix
import "../../dist/nimony/src/lib/nifcore"
from "../../dist/nimony/src/lib/bif" import load

const nim = getCurrentCompilerExe()
let dir = expandFilename(createTempDir("nim_ic_module_config_", ""))
let cache = dir / "cache"
let src = dir / "main.nim"
let exe = dir / "app".addFileExt(ExeExt)
let includes = dir / "includes"
let extra = dir / "extra"

proc artifact(folder: string; name = "consumer"): string =
  folder / (moduleSuffix(dir / (name & ".nim"), []) & ".s.bif")

proc observations(file: string): Table[string, string] =
  var m = load(file)
  var cur = m.buf.beginRead()
  cur.loopInto:
    if cur.kind == TagLit and cur.tags.tagName(cur.cursorTagId) == "configreads":
      cur.into:
        doAssert cur.kind == StrLit and strVal(cur).len == 40
        skip cur
        while cur.hasMore:
          let kind = cur.tags.tagName(cur.cursorTagId)
          if kind in ["crDefined", "crValue"]:
            cur.into:
              let name = strVal(cur)
              skip cur
              skip cur # origin
              result[kind & "/" & name] = strVal(cur)
              skip cur
          else: skip cur
    else: skip cur

proc build(flags: seq[string]; expected: string; checked: bool; source = src): string =
  let cmd = @[nim, "c", "--ic:on", "--skipUserCfg", "--hints:off", "--warnings:off",
              "--nimcache:" & cache, "--out:" & exe, "--path:" & includes] & flags & @[source]
  let r = execCmdEx(quoteShellCommand(cmd))
  doAssert r.exitCode == 0, r.output
  doAssert ("sem:consumer" in r.output) == checked, $flags & "\n" & r.output
  let run = execCmdEx(quoteShell(exe))
  doAssert run.exitCode == 0 and run.output.strip == expected, run.output
  let active = cache / "configs" / $secureHash(readFile(cache / "ic_build_args.txt"))
  result = artifact(active / "sem")

try:
  createDir(includes)
  createDir(extra)
  writeFile(includes / "settings.nim", """
const label {.strdefine: "tool.label".} = "base"
const count {.intdefine.} = 1
const enabled {.booldefine.} = false
type Color = enum red, blue
const color {.define: "tool.color".} = red
""")
  writeFile(dir / "provider.nim", """
template feature*(): bool = defined(templated)
""")
  writeFile(dir / "consumer.nim", """
import provider
include settings
static: echo "sem:consumer"
const report* = label & " " & $count & " " & $enabled & " " & $color &
  " " & $defined(presentOnly) & " " & $feature()
""")
  writeFile(src, "import consumer\necho report\n")
  let baseline = "base 1 false red false false"
  let first = build(@[], baseline, true)
  let absent = observations(first)
  doAssert absent["crDefined/presentonly"] == "false"
  doAssert absent["crDefined/tool.label"] == "false"
  doAssert absent["crDefined/templated"] == "false"
  let same = build(@["-d:unused", "-p:" & extra], baseline, false)
  doAssert readFile(first) == readFile(same)
  doAssert "crDefined/unused" notin observations(same)

  let flags = @["-d:tool.label=name", "-d:count=7", "-d:enabled", "-d:tool.color=blue",
                "-d:Present_Only=first", "-d:templated"]
  let selected = "name 7 true blue true true"
  let records = observations(build(flags, selected, true))
  doAssert records["crValue/tool.label"] == "name"
  doAssert records["crValue/count"] == "7"
  doAssert records["crValue/tool.color"] == "blue"
  doAssert records["crDefined/presentonly"] == "true"
  doAssert "crValue/presentonly" notin records
  discard build(flags & @["--define:presentOnly=second"], selected, false)
  discard build(flags & @["--undef:presentOnly"], "name 7 true blue false true", true)
  discard build(@[], baseline, false)

  # A failed import inside compiles has no dependency file to timestamp.
  # Creating the module in an already-configured path must invalidate the
  # negative lookup, including on a warm build with the exact same argv.
  writeFile(dir / "chooser.nim", """
template canImport(m: untyped): bool = compiles((; import m))
when canImport(optional):
  import optional
  const chosen* = optional.message
else:
  const chosen* = "missing"
""")
  writeFile(src, "import consumer, chooser\necho report, \" \", chosen\n")
  discard build(@["--path:" & extra], baseline & " missing", false)
  writeFile(extra / "optional.nim", "const message* = \"found\"\n")
  discard build(@["--path:" & extra], baseline & " found", false)
  removeFile(extra / "optional.nim")
  discard build(@["--path:" & extra], baseline & " missing", false)
  writeFile(src, "import consumer\necho report\n")

  # genBif in a classic compiler run carries the module's own observations.
  let normal = dir / "normal"
  let compiled = execCmdEx(quoteShellCommand(@[nim, "c", "--genBif:on", "--hints:off",
    "--warnings:off", "--nimcache:" & normal, "--path:" & includes] & flags & @[src]))
  doAssert compiled.exitCode == 0, compiled.output
  let standalone = observations(artifact(normal))
  doAssert standalone["crDefined/presentonly"] == "true"
  doAssert standalone["crValue/count"] == "7"

  # A module requesting searchPaths consumes the search path ordering itself.
  # A module requesting projectPath can share an active config with a different
  # entry project. Revalidate its answer even on a warm switch back.
  writeFile(dir / "context.nim", """
import std/compilesettings
const paths = querySettingSeq(MultipleValueSetting.searchPaths)
const hasExtra* = """ & extra.escape & """ in paths
const project* = querySetting(SingleValueSetting.projectPath)
""")
  for folder in [dir / "one", dir / "two"]:
    createDir(folder)
    writeFile(folder / "entry.nim",
      "import ../consumer, ../context\necho report, \" \", project, \" \", hasExtra\n")
  for folder in [dir / "one", dir / "two", dir / "one"]:
    let entry = folder / "entry.nim"
    discard build(@[], baseline & " " & folder & " false", false, entry)
    discard build(@["--path:" & extra], baseline & " " & folder & " true", false, entry)

  # Mutually importing modules build as one unit. Each BIF still describes
  # its own queries, including ones made by a deferred procedure body.
  writeFile(dir / "cyclea.nim", """
import cycleb {.cyclic.}
proc flags*(): string = $defined(cycleFirst) & " " & $other()
""")
  writeFile(dir / "cycleb.nim", """
import cyclea {.cyclic.}
proc other*(): bool = defined(cycleSecond)
""")
  writeFile(src, "import consumer, cyclea\necho report, \" \", flags()\n")
  let cyclic = build(@["-d:cycleSecond"], baseline & " false true", false).parentDir
  let readsA = observations(artifact(cyclic, "cyclea"))
  let readsB = observations(artifact(cyclic, "cycleb"))
  doAssert readsA["crDefined/cyclefirst"] == "false" and "crDefined/cyclesecond" notin readsA
  doAssert readsB["crDefined/cyclesecond"] == "true" and "crDefined/cyclefirst" notin readsB
  discard build(@["-d:cycleFirst"], baseline & " true false", false)

  when defined(posix):
    # Directory symlinks in a direct import must identify the same BIF in the
    # scanner and in sem. Retargeting the symlink changes a warm lookup.
    for provider in ["left", "right"]:
      createDir(dir / provider)
      writeFile(dir / provider / "choice.nim", "const tag* = " & provider.escape & "\n")
    writeFile(src, "import consumer, vendor/choice\necho report, \" \", tag\n")
    for provider in ["left", "right", "left"]:
      createSymlink(dir / provider, dir / "vendor")
      discard build(@[], baseline & " " & provider, false)
      removeFile(dir / "vendor")

  # Both drivers select the same project config file and build graph. Their
  # snapshots, resolved imports, generated objects and binaries must agree
  # with their own arguments throughout the build.
  writeFile(src, "import choice\nconst num {.intdefine.} = 0\nconst n = num\necho tag, n\n")
  var children: seq[Process]
  try:
    for i in 1..2:
      let path = dir / ("choice" & $i)
      createDir(path)
      writeFile(path / "choice.nim", "const tag* = " & ("path" & $i).escape & "\n")
      children.add startProcess(nim, args = @["c", "--ic:on", "--hints:off", "--warnings:off",
        "--skipUserCfg", "--nimcache:" & cache, "--out:" & (dir / ("app" & $i)).addFileExt(ExeExt),
        "--path:" & path, "-d:num=" & $i, src], options = {poStdErrToStdOut})
    for i, child in children:
      let log = child.outputStream.readAll()
      doAssert child.waitForExit() == 0, log
      let run = execCmdEx(quoteShell((dir / ("app" & $(i + 1))).addFileExt(ExeExt)))
      doAssert run.exitCode == 0 and run.output.strip == "path" & $(i + 1) & $(i + 1), run.output
  finally:
    for child in children: child.close()
finally:
  removeDir(dir)
