##[
benchmark showing that importing lots of small modules is cheap, thus justifying
approaches like megatest. This could be used as a regression test for compilation speed.

This benchmark compares:
* -d:caseAllImports import n modules (each with 1 symbol), and call each symbol
* -d:caseAllSymbols define n modules, and call each symbol
* -d:caseWithStdModules import os
* -d:caseNone import nothing (baseline); still costly because of nimscript which imports os
  (pending https://github.com/nim-lang/Nim/issues/14179#issuecomment-625200718)

on OSX, usign devel 1.3.5 30c09e460778099633db084532672970954bb328 I get this:
it shows that importing n=1000 small modules costs 6ms per module with --force,
and 1ms per module with recompilation with no change.

n: 1000
opt: caseNone           force: -f t: 0.3955578804016113
opt: caseNone           force:    t: 0.2422900199890137
opt: caseAllImports     force: -f t: 5.811758041381836
opt: caseAllImports     force:    t: 0.9440269470214844
opt: caseAllSymbols     force: -f t: 0.5444350242614746
opt: caseAllSymbols     force:    t: 0.2357771396636963
opt: caseWithStdModules force: -f t: 0.7344591617584229
opt: caseWithStdModules force:    t: 0.5402710437774658
]##

import std/[strformat,os,times,strutils]
import std/private/asciitables

proc quoted(a: string): string = result.addQuoted(a)

proc genFiles(dir: string, n: int): string =
  createDir dir

  var codeMain = ""
  var codeAllImports = ""
  var codeAllSymbols = ""

  let fileMain = dir / "main.nim"
  let fileAllImports = dir / "allimports.nim"
  let fileAllSymbols = dir / "allsymbols.nim"

  for i in 0..<n:
    let filei = dir / fmt"mod{i}.nim"
    let codei = fmt"""
proc fn{i}* = discard
"""
    writeFile(filei, codei)

    codeAllSymbols.add fmt"""
{codei}
"""

    codeAllImports.add fmt"""
import {filei.quoted}
"""

  for i in 0..<n:
    codeAllSymbols.add fmt"""
fn{i}()
"""
    codeAllImports.add fmt"""
fn{i}()
"""

  codeMain.add fmt"""
when defined(caseAllImports):
  import {fileAllImports.quoted}
when defined(caseAllSymbols):
  import {fileAllSymbols.quoted}
when defined(caseWithStdModules):
  import std/os
"""

  writeFile(fileMain, codeMain)
  writeFile(fileAllImports, codeAllImports)
  writeFile(fileAllSymbols, codeAllSymbols)
  return fileMain

proc bench(body: proc()): float =
  let t = epochTime()
  body()
  result = epochTime() - t

proc main()=
  let dir = getTempDir()
  echo dir
  let n = 1000
  let fileMain = genFiles(dir, n)
  const nim = getCurrentCompilerExe()
  var msg = ""
  for opt in "caseNone caseAllImports caseAllSymbols caseWithStdModules".split:
    for force in ["-f", ""]:
      let cmd =  fmt"{nim} c {force} --skipparentcfg --skipusercfg --skipcfg --hint:successx --hint:processing:off --hint:link:off --hint:cc:off --warnings:off -d:{opt} --path:lib/pure/ --path:lib/core --path:lib/posix {fileMain}"
      let dt = bench(proc() = doAssert execShellCmd(cmd) == 0)
      msg.add &"opt: {opt}\tforce: {force}\tt: {dt}\n"
  echo &"n: {n}\n" & msg.alignTable


when isMainModule:
  main()
