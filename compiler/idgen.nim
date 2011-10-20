#
#
#           The Nimrod Compiler
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains a simple persistent id generator.

import idents, strutils, os, options

var gFrontEndId, gBackendId*: int

const
  debugIds* = false

when debugIds:
  import intsets
  
  var usedIds = InitIntSet()

proc registerID*(id: PIdObj) = 
  when debugIDs: 
    if (id.id == - 1) or ContainsOrIncl(usedIds, id.id): 
      InternalError("ID already used: " & $id.id)
  
proc getID*(): int {.inline.} = 
  result = gFrontEndId
  inc(gFrontEndId)

proc backendId*(): int {.inline.} = 
  result = gBackendId
  inc(gBackendId)

proc setId*(id: int) {.inline.} = 
  gFrontEndId = max(gFrontEndId, id + 1)

proc IDsynchronizationPoint*(idRange: int) = 
  gFrontEndId = (gFrontEndId div IdRange + 1) * IdRange + 1

proc toGid(f: string): string =
  result = options.completeGeneratedFilePath(f.addFileExt("gid"))

proc saveMaxIds*(project: string) =
  var f = open(project.toGid, fmWrite)
  f.writeln($gFrontEndId)
  f.writeln($gBackEndId)
  f.close()
  
proc loadMaxIds*(project: string) =
  var f: TFile
  if open(f, project.toGid, fmRead):
    var frontEndId = parseInt(f.readLine)
    var backEndId = parseInt(f.readLine)
    gFrontEndId = max(gFrontEndId, frontEndId)
    gBackEndId = max(gBackEndId, backEndId)
    f.close()

