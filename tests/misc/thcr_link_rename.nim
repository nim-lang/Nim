discard """
joinable: false
disabled: windows
"""

# A program built with hot code reloading reloads a module's library as soon
# as the file looks newer, so the linker must never write that file in place:
# the program could load it half written, or find it missing while the linker
# replaces it. The build links each library beside its final name and moves
# it into place once it is complete.

import stdtest/specialpaths
import std/[os, osproc, strformat, strutils, sequtils]

const nim = getCurrentCompilerExe()

let dir = buildDir / "thcr_link_rename"
removeDir dir
createDir dir
writeFile dir / "mods.nim", "proc greeting*(): string = \"v1\"\n"
writeFile dir / "main.nim", "import mods\necho greeting()\n"

# A linker that records the file each call writes, then links as usual.
let log = dir / "outputs.txt"
let wrapper = dir / "linker.sh"
const realLinker = when defined(macosx): "clang" else: "gcc"
writeFile wrapper, fmt"""#!/bin/sh
prev=""
for a in "$@"; do
  if [ "$prev" = "-o" ]; then echo "$a" >> "{log}"; fi
  prev="$a"
done
exec {realLinker} "$@"
"""
setFilePermissions(wrapper, {fpUserRead, fpUserWrite, fpUserExec})

let nimcache = dir / "nc"
let (output, exitCode) = execCmdEx(fmt"{nim} c --hints:off --warnings:off " &
  fmt"--hotCodeReloading:on --nimcache:{nimcache} --cc:{realLinker} " &
  fmt"--{realLinker}.linkerexe:{wrapper} -o:{dir / ""main""} {dir / ""main.nim""}")
doAssert exitCode == 0, output

let libraries = toSeq(walkFiles(nimcache / "*" & DynlibFormat.splitFile.ext))
doAssert libraries.len > 1, $libraries

let written = readFile(log).splitLines.filterIt(it.len > 0).mapIt(it.strip(chars = {'"', '\''}))
doAssert written.len > 0
for library in libraries:
  doAssert library notin written, library & " was written in place by the linker"
