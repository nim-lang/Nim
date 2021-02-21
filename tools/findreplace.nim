##[
Experimental API, subject to change

## Example usage
using `ripgrep` for file listing:
rg -l --color=auto -F 'defined(macosx)' lib | nim r tools/findreplace.nim --pattern:'defined\(macosx\)' --replacement:'defined(osx)' --dryrun:false

## Design goal
separation of concern between file listing and replacement, thanks to unix pipes,
so users can choose whatever program for file listing
]##


import std/[re, strutils, strformat, os, osproc, sequtils]
# xxx pending #17129, use std/nre instead of std/re

type Data = object
  dryrun: bool
  reg: Regex
  pattern: string
  replacement: string
  gitOpt: string

type Output = object
  numProcessed: int
  filesModif: seq[string]
  filesNoModif: seq[string]

proc showDiff(file1: string, content2: string, gitOpt: string): string =
  ## note that `file1` is a file path, whereas `content2` is a content.
  let cmd = fmt"git --no-pager diff --no-index {gitOpt} -- {file1.quoteShell} -"
  var status: int
  (result, status) = execCmdEx(cmd, input = content2)
  stripLineEnd(result)
  if status == 0:
    doAssert result.len == 0, result
  else:
    doAssert result.len > 0

proc findReplaceFile*(result: var Output, data: Data, file: string) =
  let s = file.readFile
  let s2 = s.replace(data.reg, data.replacement)
  let prefix = &"\nprocessing [{result.numProcessed}] {file}: "
  result.numProcessed.inc
  if s == s2:
    result.filesNoModif.add file
    echo prefix & "same"
  else:
    result.filesModif.add file
    if data.dryrun:
      let diff = showDiff(file, s2, data.gitOpt)
      doAssert diff.len > 0
      echo prefix & "\n" & diff
    else:
      echo prefix & "overwritten"
      writeFile(file, s2)

proc cmdFindReplace*(pattern: string, replacement: string, gitOpt = "", dryrun = true) =
  let data = Data(dryrun: dryrun, pattern: pattern, replacement: replacement, reg: re(pattern), gitOpt: gitOpt)
  var output: Output
  for line in stdin.lines:
    findReplaceFile(output, data, line)
  template process(a): untyped = a.mapIt(" " & it).join("\n")
  echo fmt"""
summary:
files with a change:
{output.filesModif.process}
files with no change:
{output.filesNoModif.process}
"""

when isMainModule:
  import pkg/cligen
  dispatch cmdFindReplace
