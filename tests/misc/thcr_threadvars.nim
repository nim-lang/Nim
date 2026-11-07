discard """
joinable: false
disabled: windows
"""

# A threadvar under hot code reloading keeps the meaning it has without it:
# each thread has its own value, a module other than the declaring one can
# read and write it, and reloading the declaring module keeps the value, as
# it keeps the value of a global. Before, the program did not link, and a
# threadvar read only by its own module went back to zero on a reload.
#
# The program is built with --threads:on, so the HCR runtime and nimrtl are
# built beside it with the same setting.

import stdtest/specialpaths
import std/[os, osproc, strformat, strutils, streams, strtabs]

const nim = getCurrentCompilerExe()
let lib = nim.parentDir.parentDir / "lib"

let dir = buildDir / "thcr_threadvars"
removeDir dir
createDir dir

# The program finds nimhcr and nimrtl next to itself: through its rpath on
# macOS, through LD_LIBRARY_PATH elsewhere, as in the dll category. An rpath
# of $ORIGIN does not survive the shell that runs the linker.
const rpath = when defined(macosx): "--passL:-rpath --passL:@loader_path" else: ""
let musl = when defined(linux) and defined(musl): " -d:musl" else: ""

proc build(args: string) =
  let (output, exitCode) = execCmdEx(fmt"{nim} c --hints:off --warnings:off --threads:on{musl} {args}",
                                     workingDir = dir)
  doAssert exitCode == 0, output

build fmt"--outdir:{dir} {lib / ""nimrtl.nim""}"
build fmt"--outdir:{dir} {rpath} {lib / ""nimhcr.nim""}"

proc writeModule(version: string) =
  writeFile dir / "tv.nim", fmt"""
var hits* {{.threadvar.}}: int
proc version*(): string = "{version}"
"""

writeModule("v1")
writeFile dir / "main.nim", """
import std/[os, hotcodereloading]
import tv

proc worker(n: int) {.thread.} =
  for i in 1 .. n:
    inc hits
  echo "thread ", n, " sees ", hits

var t1, t2: Thread[int]
createThread(t1, worker, 3)
joinThread(t1)
createThread(t2, worker, 5)
joinThread(t2)
inc hits
echo "main sees ", hits, " ", version()
while not fileExists("reload.stamp"):
  sleep 20
if hasAnyModuleChanged():
  performCodeReload()
inc hits
echo "after the reload main sees ", hits, " ", version()
"""

let mainBuild = fmt"--hotCodeReloading:on --nimcache:{dir / ""nc""} {rpath} main.nim"
build mainBuild

let env = newStringTable()
for key, value in envPairs():
  env[key] = value
env["LD_LIBRARY_PATH"] = dir
let program = startProcess(dir / "main", workingDir = dir, env = env,
                           options = {poStdErrToStdOut})
let output = program.outputStream
var lines: seq[string]
while lines.len < 3:
  lines.add output.readLine()

writeModule("v2")
build mainBuild
writeFile dir / "reload.stamp", ""
lines.add output.readLine()
doAssert program.waitForExit() == 0
program.close()

doAssert lines == @["thread 3 sees 3", "thread 5 sees 5", "main sees 1 v1",
                    "after the reload main sees 2 v2"], lines.join("\n")
