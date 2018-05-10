#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains a simple persistent id generator.

import idents, strutils, os, options

var gFrontEndId*: int

const
  debugIds* = false

when debugIds:
  import intsets

  var usedIds = initIntSet()

proc registerID*(id: PIdObj) =
  when debugIds:
    if id.id == -1 or containsOrIncl(usedIds, id.id):
      internalError("ID already used: " & $id.id)

proc getID*(): int {.inline.} =
  result = gFrontEndId
  inc(gFrontEndId)

proc setId*(id: int) {.inline.} =
  gFrontEndId = max(gFrontEndId, id + 1)

proc idSynchronizationPoint*(idRange: int) =
  gFrontEndId = (gFrontEndId div idRange + 1) * idRange + 1

proc toGid(conf: ConfigRef; f: string): string =
  # we used to use ``f.addFileExt("gid")`` (aka ``$project.gid``), but this
  # will cause strange bugs if multiple projects are in the same folder, so
  # we simply use a project independent name:
  result = options.completeGeneratedFilePath(conf, "nim.gid")

proc saveMaxIds*(conf: ConfigRef; project: string) =
  var f = open(toGid(conf, project), fmWrite)
  f.writeLine($gFrontEndId)
  f.close()

proc loadMaxIds*(conf: ConfigRef; project: string) =
  var f: File
  if open(f, toGid(conf, project), fmRead):
    var line = newStringOfCap(20)
    if f.readLine(line):
      var frontEndId = parseInt(line)
      if f.readLine(line):
        # var backEndId = parseInt(line)
        gFrontEndId = max(gFrontEndId, frontEndId)
    f.close()
