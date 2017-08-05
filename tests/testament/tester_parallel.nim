import os, osproc, ospaths, strutils, threadpool
from math import nextPowerOfTwo

proc main() =
  ## Run testament in parallel, spawning off a new process for each category
  let workerCount = 
    if (let numCpus = countProcessors(); numCpus != 0):
      numCpus
    else:
      1
  
  # Additional categories added when running testament with "all"
  const AdditionalCategories = ["debugger", "examples", "lib"]
  
  let testDir = "tests" & DirSep
  let cmdTemplate = "tests/testament/tester --pedantic c $# -d:nimCoroutines"

  # Sequence of commands 
  var cmds = newSeqOfCap[string](nextPowerOfTwo(110 + AdditionalCategories.len))

  for additional_cat in AdditionalCategories:
    cmds.add(cmdTemplate.format(additional_cat))

  for kind, dir in walkDir(testDir):
    assert testDir.startsWith(testDir)
    let cat = dir[testDir.len .. ^1]
    
    if kind == pcDir and cat notin ["testament", "testdata", "nimcache"]:
      # Spawn worker process for this category
      cmds.add(cmdTemplate.format(cat))
  
  # Now launch all commands with set # of processes
  var cmdResults: seq[FlowVar[TaintedString]] = newSeq[FlowVar[TaintedString]](len(cmds))

  setMaxPoolSize(workerCount)

  for i, cmd in cmds:
    cmdResults[i] = spawn execProcess(command = cmd)

  sync()

  for res in cmdResults:
    echo string(^res)

when isMainModule:
  main()
