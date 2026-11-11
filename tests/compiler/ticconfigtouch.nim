discard """
  joinable: false
"""

# A `nim.cfg` saved without changes must cost one run of the precompiled config
# producer, not one on every later `nim ic`: the producer writes the config
# only when its content changes, so its own mtime cannot say when the sources
# were last read. A real change must still be picked up.
import std/[assertions, os, osproc, strutils, tempfiles, times]

const nim = getCurrentCompilerExe()

let dir = createTempDir("nim_ic_config_touch_", "")
let cache = dir / "nc"
let binary = dir / "prog".addFileExt(ExeExt)
let cfg = dir / "nim.cfg"

proc build(expected: string) =
  let args = [nim, "ic", "--hints:off", "--warnings:off", "--skipUserCfg",
    "--nimcache:" & cache, "--out:" & binary, dir / "main.nim"]
  let compiled = execCmdEx(quoteShellCommand(args))
  doAssert compiled.exitCode == 0, compiled.output
  let executed = execCmdEx(quoteShell(binary))
  doAssert executed.exitCode == 0, executed.output
  doAssert executed.output.strip == expected, executed.output

proc producerRun(): Time =
  ## The producer's arguments are written next to the config after every run.
  var found: seq[string] = @[]
  for file in walkFiles(cache / "ic_config_*.cfg.nif.args"): found.add file
  doAssert found.len == 1, $found
  getLastModificationTime(found[0])

try:
  writeFile(cfg, "--define:cfgValue=1\n")
  writeFile(dir / "main.nim", """
const cfgValue {.intdefine.} = 0
echo cfgValue
""")
  build("1")
  setLastModificationTime(cfg, getTime())
  build("1")
  let touched = producerRun()
  build("1")
  doAssert producerRun() == touched, "the producer ran again for an unchanged nim.cfg"

  writeFile(cfg, "--define:cfgValue=2\n")
  build("2")
finally:
  removeDir(dir)
