#
#
#           The Nim Compiler
#        (c) Copyright 2023 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import ".." / ic / [bitabs, rodfiles]
import nirinsts, nirtypes, nirlineinfos

type
  NirModule* = object
    code*: Tree
    man*: LineInfoManager
    types*: TypeGraph
    lit*: Literals
    symnames*: SymNames

proc load*(filename: string): NirModule =
  let lit = Literals()
  result = NirModule(lit: lit, types: initTypeGraph(lit))
  var r = rodfiles.open(filename)
  try:
    r.loadHeader(nirCookie)
    r.loadSection stringsSection
    r.load result.lit.strings

    r.loadSection numbersSection
    r.load result.lit.numbers

    r.loadSection bodiesSection
    r.load result.code

    r.loadSection typesSection
    r.load result.types

    r.loadSection sideChannelSection
    r.load result.man

    r.loadSection symnamesSection
    r.load result.symnames

  finally:
    r.close()

proc store*(m: NirModule; outp: string) =
  var r = rodfiles.create(outp)
  try:
    r.storeHeader(nirCookie)
    r.storeSection stringsSection
    r.store m.lit.strings

    r.storeSection numbersSection
    r.store m.lit.numbers

    r.storeSection bodiesSection
    r.store m.code

    r.storeSection typesSection
    r.store m.types

    r.storeSection sideChannelSection
    r.store m.man

    r.storeSection symnamesSection
    r.store m.symnames

  finally:
    r.close()
  if r.err != ok:
    raise newException(IOError, "could store into: " & outp)
