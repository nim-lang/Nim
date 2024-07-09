#
#
#           The Nim Compiler
#        (c) Copyright 2023 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Nir Compiler. Currently only supports a "view" command.

import ".." / ic / [bitabs, rodfiles]
import nirinsts, nirtypes, nirlineinfos

proc view(filename: string) =
  var lit = Literals()

  var r = rodfiles.open(filename)
  var code = default Tree
  var man = default LineInfoManager
  var types = initTypeGraph(lit)
  try:
    r.loadHeader(nirCookie)
    r.loadSection stringsSection
    r.load lit.strings

    r.loadSection numbersSection
    r.load lit.numbers

    r.loadSection bodiesSection
    r.load code

    r.loadSection typesSection
    r.load types

    r.loadSection sideChannelSection
    r.load man

  finally:
    r.close()

  var res = ""
  allTreesToString code, lit.strings, lit.numbers, res
  res.add "\n# TYPES\n"
  nirtypes.toString res, types
  echo res

import std / os

view paramStr(1)
