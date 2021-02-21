#
#
#              The Nim Tester
#        (c) Copyright 2017 Andreas Rumpf
#
#    Look at license.txt for more info.
#    All rights reserved.

import strutils, os, osproc, json

type
  MachineId* = distinct string
  CommitId = distinct string

proc `$`*(id: MachineId): string {.borrow.}

var
  thisMachine: MachineId
  thisCommit: CommitId
  thisBranch: string

proc getMachine*(): MachineId =
  var name = execProcess("hostname").strip
  if name.len == 0:
    name = when defined(posix): getEnv("HOSTNAME")
           else: getEnv("COMPUTERNAME")
  if name.len == 0:
    quit "cannot determine the machine name"

  result = MachineId(name)

proc getCommit(): CommitId =
  const commLen = "commit ".len
  let hash = execProcess("git log -n 1").strip[commLen..commLen+10]
  thisBranch = execProcess("git symbolic-ref --short HEAD").strip
  if hash.len == 0 or thisBranch.len == 0: quit "cannot determine git HEAD"
  result = CommitId(hash)

var
  results: File
  currentCategory: string
  entries: int

proc writeTestResult*(name, category, target, action, result, expected, given: string) =
  createDir("testresults")
  if currentCategory != category:
    if currentCategory.len > 0:
      results.writeLine("]")
      close(results)
    currentCategory = category
    results = open("testresults" / category.addFileExt"json", fmWrite)
    results.writeLine("[")
    entries = 0

  let jentry = %*{"name": name, "category": category, "target": target,
    "action": action, "result": result, "expected": expected, "given": given,
    "machine": thisMachine.string, "commit": thisCommit.string, "branch": thisBranch}
  if entries > 0:
    results.writeLine(",")
  results.write($jentry)
  inc entries

proc open*() =
  thisMachine = getMachine()
  thisCommit = getCommit()

proc close*() =
  if currentCategory.len > 0:
    results.writeLine("]")
    close(results)
