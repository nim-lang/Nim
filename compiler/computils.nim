#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import osproc

proc getGitHeadSha1*(): string =
  ## Get the current git HEAD sha1
  var
    v: tuple[output: TaintedString, exitCode: int]

  try:
    v = execCmdEx("git show -s --format=%H HEAD")
  except:
    v.exitCode = -1000

  if v.exitCode == 0:
    result = v.output
  else:
    result = "?"
