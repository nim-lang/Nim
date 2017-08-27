import os, osproc, ospaths, strutils, random
from math import nextPowerOfTwo

var work: Channel[string]
var output: Channel[string]
var die: Channel[bool]

proc testWorker(num: int) {.thread.} =
  var (avail, shouldDie) = die.tryRecv()

  # Keep doing tryRecv on work and die break if shouldDie, if workChunk is nil,
  # then just try again
  var
    workAvail: bool
    workChunk: string

  while not shouldDie:
    (workAvail, workChunk) = work.tryRecv()
    # Sending does not block
    if workAvail:
      output.send(string(execProcess(command = workChunk)))

    (avail, shouldDie) = die.tryRecv()

  output.send("Worker $# dead".format(num))

proc main() =
  ## Run testament in parallel, spawning off a new process for each category
  work.open()
  output.open()
  die.open()

  let workerCount =
    if (let numCpus = countProcessors(); numCpus != 0):
      numCpus
    else:
      1
  
  # Additional categories added when running testament with "all"
  const AdditionalCategories = ["debugger", "examples", "lib"]
  
  let testDir = "tests" & DirSep
  let cmdTemplate = "tests/testament/tester --pedantic c $# -d:nimCoroutines"

  var totalJobs = 0

  var workerThreads = newSeq[Thread[int]](workerCount)

  # Create workers
  for i in 0 .. <len(workerThreads):
    createThread(workerThreads[i], testWorker, i)

  for kind, dir in walkDir(testDir):
    assert testDir.startsWith(testDir)
    let cat = dir[testDir.len .. ^1]
    
    if kind == pcDir and cat notin ["testament", "testdata", "nimcache"]:
      # Send work to worker
      work.send(cmdTemplate.format(cat))
      totalJobs.inc
  
  for additional_cat in AdditionalCategories:
    work.send(cmdTemplate.format(additional_cat))
    totalJobs.inc

  for i in 0 .. <totalJobs:
    echo output.recv()
  
  work.close()

  for i in 0 .. <workerCount:
    die.send(true)


when isMainModule:
  main()