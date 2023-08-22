#
#           Atlas Package Cloner
#        (c) Copyright 2023 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Extract the version of commonly used compilers.
## For Nim we use the version plus the commit hash.

import std / [osproc, strscans]

proc detectGccVersion*(): string =
  result = ""
  let (outp, exitCode) = execCmdEx("gcc -v")
  if exitCode == 0:
    var prefix: string
    var a, b, c: int
    if scanf(outp, "$*\ngcc version $i.$i.$i", prefix, a, b, c):
      result = $a & "." & $b & "." & $c

proc detectClangVersion*(): string =
  result = ""
  let (outp, exitCode) = execCmdEx("clang -v")
  if exitCode == 0:
    var a, b, c: int
    if scanf(outp, "clang version $i.$i.$i", a, b, c):
      result = $a & "." & $b & "." & $c

proc detectNimVersion*(): string =
  result = ""
  let (outp, exitCode) = execCmdEx("nim -v")
  if exitCode == 0:
    var a, b, c: int
    if scanf(outp, "Nim Compiler Version $i.$i.$i", a, b, c):
      result = $a & "." & $b & "." & $c
      var prefix, commit: string
      if scanf(outp, "$*\ngit hash: $w", prefix, commit):
        result.add ' '
        result.add commit
