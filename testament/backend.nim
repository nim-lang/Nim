#
#
#              The Nim Tester
#        (c) Copyright 2017 Andreas Rumpf
#
#    Look at license.txt for more info.
#    All rights reserved.

import algorithm, strutils, os, osproc, json, types

type
  MachineId* = distinct string
  CommitId = distinct string

  Output = object
    category: string
    output: seq[string]

proc `$`*(id: MachineId): string {.borrow.}
#proc `$`(id: CommitId): string {.borrow.} # not used

var
  thisMachine: MachineId
  thisCommit: CommitId
  thisBranch: string

{.experimental.}
proc `()`(cmd: string{lit}): string = cmd.execProcess.string.strip

proc getMachine*(): MachineId =
  var name = "hostname"()
  if name.len == 0:
    name = when defined(posix): getenv"HOSTNAME".string
           else: getenv"COMPUTERNAME".string
  if name.len == 0:
    quit "cannot determine the machine name"

  result = MachineId(name)

proc getCommit(): CommitId =
  const commLen = "commit ".len
  let hash = "git log -n 1"()[commLen..commLen+10]
  thisBranch = "git symbolic-ref --short HEAD"()
  if hash.len == 0 or thisBranch.len == 0: quit "cannot determine git HEAD"
  result = CommitId(hash)

var
  results: seq[Output]

proc writeTestResult*(id, name, category, target,
                      action, result, expected, given: string) =
  var i = -1
  for j in 0..<results.len:
    if results[j].category == category:
      i = j
      break

  if i == -1:
    i = results.len
    results.add Output(category: category)

  let jentry = %*{"id": id, "name": name, "category": category, "target": target,
    "action": action, "result": result, "expected": expected, "given": given,
    "machine": thisMachine.string, "commit": thisCommit.string, "branch": thisBranch}
  results[i].output.add $jentry

proc open*() =
  thisMachine = getMachine()
  thisCommit = getCommit()
  createDir("testresults")

proc close*() =
  for r in results.mitems():
    var sep = ""

    sort(r.output, system.cmp)
    let f = open("testresults" / r.category.addFileExt"json", fmWrite)
    f.write("[")

    for o in r.output:
      f.writeLine(sep)
      f.write(o)
      sep = ","
    f.writeLine("")
    f.writeLine("]")
    f.close()
  results = @[]